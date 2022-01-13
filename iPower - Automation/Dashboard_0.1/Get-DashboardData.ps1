# INCLUDE FUNCTIONS
try {
    . ("C:\Dashboard\Functions.ps1")
}
catch {
    Write-Host -ForegroundColor Magenta "Error while loading supporting PowerShell Scripts" 
}

Function Fix-Cert {
    if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
} else {
    Write-Host -ForegroundColor Magenta "Cert OK, Skipping Fix"
}
    [ServerCertificateValidationCallback]::Ignore()

    return
}

Function Get-HMCData {
    Param (
        [Parameter(Mandatory=$true)][String]$Server,
        [Parameter(Mandatory=$true)][String]$User,
        [Parameter(Mandatory=$true)][String]$Password
    )

    # SET TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # LOG ON, GET SESSION ID
    $Token = HmcLogon -Server $Server -User $User -Password $Password

    # GET MANAGED SYSTEMS FROM HMC
    Write-Host -ForegroundColor Yellow "Getting Managed Systems..." -NoNewline
    $ManagedSystems = HmcRestGet -Token $Token -Uri "https://$($Server):12443/rest/api/uom/ManagedSystem"
    #$ManagedSystems = HmcRestGet -Token $Token -Uri "https://$($Server):12443/rest/api/uom/ManagedSystem/f51a52fe-388f-3514-b55f-f7e3fd2464d3"
    Write-Host -ForegroundColor Green "DONE!"

    # GET LOGICAL PARTITIONS FROM HMC
    Write-Host -ForegroundColor Yellow "Getting Logical Partitions..." -NoNewline
    $LogicalPartitions = HmcRestGet -Token $Token -Uri "https://$($Server):12443/rest/api/uom/LogicalPartition"
    Write-Host -ForegroundColor Green "DONE!"

    # LOG OFF API SESSION
    Start-Sleep -Seconds 1
    HmcLogoff -Server $Server -Token $Token

    # RETURN
    return @($ManagedSystems,$LogicalPartitions)

}

# FIX CERT
Fix-Cert

# GET CREDENTIALS
$CredObj = Import-Clixml "C:\Dashboard\Data\Credential.xml"

# GET MS DATA
$HMCData = Get-HMCData -Server "pwrhmc02.ipower.local" -User "$($CredObj.GetNetworkCredential().Username)" -Password "$($CredObj.GetNetworkCredential().Password)"
$ManagedSystems = $HMCData[0]
$LogicalPartitions = $HMCData[1]

# GET CPW-DATA FROM FILE
$SystemCPW = Import-Csv -Encoding UTF8 -Path "C:\Dashboard\Data\SystemCPW.csv"

# CREATE DTO
$ManagedSystemsDTO = @()
foreach ($ManagedSystem in $ManagedSystems) {
    #$CurrentSystem = $ManagedSystem.entry
    $CurrentSystem = $ManagedSystem
    $SystemDTO = @{
        SystemUUID = [string]($CurrentSystem.id)
        SystemName = [string]($CurrentSystem.content.ManagedSystem.SystemName."#text")
        SystemTypeModel = [string]"$($CurrentSystem.content.ManagedSystem.MachineTypeModelAndSerialNumber.MachineType."#text")-$($CurrentSystem.content.ManagedSystem.MachineTypeModelAndSerialNumber.Model."#text")"
        ConfigurableSystemMemoryGB = [decimal]([int]($CurrentSystem.content.ManagedSystem.AssociatedSystemMemoryConfiguration.ConfigurableSystemMemory."#text") / 1024)
        CurrentAvailableSystemMemoryGB = [decimal]([int]($CurrentSystem.content.ManagedSystem.AssociatedSystemMemoryConfiguration.CurrentAvailableSystemMemory."#text") / 1024)
        ConfigurableSystemProcessorUnits = [decimal]($CurrentSystem.content.ManagedSystem.AssociatedSystemProcessorConfiguration.ConfigurableSystemProcessorUnits."#text")
        CurrentAvailableSystemProcessorUnits = [decimal]($CurrentSystem.content.ManagedSystem.AssociatedSystemProcessorConfiguration.CurrentAvailableSystemProcessorUnits."#text")
        SystemAttention = [string]""
        RunningPartitions = 0
        NotActivePartitions = 0
        AttentionPartitions = 0
        NotAvailablePartitions = 0
        SupportedModes = ""
    }
    $SystemDTO.Add("ConfigurableCPW",[int](($SystemCPW | Where {$_.SystemUUID -eq $SystemDTO.SystemUUID}).ProcUnitCPW) * $SystemDTO.ConfigurableSystemProcessorUnits)
    $SystemDTO.Add("CurrentAvailableCPW",[int](($SystemCPW | Where {$_.SystemUUID -eq $SystemDTO.SystemUUID}).ProcUnitCPW) * $SystemDTO.CurrentAvailableSystemProcessorUnits)
    if ($CurrentSystem.content.ManagedSystem.PhysicalSystemAttentionLEDState."#text" -match "true") {
        $SystemDTO.SystemAttention += "<span>Physical</span>"
    }
    if ($CurrentSystem.content.ManagedSystem.VirtualSystemAttentionLEDState."#text" -match "true") {
        $SystemDTO.SystemAttention += "<span>Virtual</span>"
    }

    # GET LOGICAL PARTITION INFO
    $UnknownState = 0
    foreach ($Href in ($CurrentSystem.content.ManagedSystem.AssociatedLogicalPartitions.link.href)) {
        $LPar = $LogicalPartitions | Where {$_.id -match ($Href -replace "^.*/","")}
        if ($LPar.content.LogicalPartition.PartitionState."#text" -match "running") {
            $SystemDTO.RunningPartitions++
        } elseif ($LPar.content.LogicalPartition.PartitionState."#text" -match "not activated") {
            $SystemDTO.NotActivePartitions++
        } elseif ($LPar.content.LogicalPartition.PartitionState."#text" -match "not available") {
            $SystemDTO.NotAvailablePartitions++
        } else {
            Write-Host -ForegroundColor Magenta "UNKNOWN LPAR STATE: $($LPar.content.LogicalPartition.PartitionState."#text")"
            $UnknownState++
        }

        if ($LPar.content.LogicalPartition.IsVirtualServiceAttentionLEDOn."#text" -match "true") {
            $SystemDTO.AttentionPartitions++
        }

    }
    $SystemDTO.Add("PartitionSummary","<span class='green'>$($SystemDTO.RunningPartitions)</span><span class='grey'>$($SystemDTO.NotActivePartitions)</span>")
    if ($SystemDTO.AttentionPartitions -gt 0) {
        $SystemDTO.PartitionSummary += "<span class='yellow'>$($SystemDTO.AttentionPartitions)</span>"
    }
    if ($SystemDTO.NotAvailablePartitions -gt 0) {
        $SystemDTO.PartitionSummary += "<span class='red'>$($SystemDTO.NotAvailablePartitions)</span>"
    }
    if ($UnknownState -gt 0) {
        $SystemDTO.PartitionSummary += "<span class='orange'>$($UnknownState)</span>"
    }

    # GET POWER GEN
    $SupportedGens = ($CurrentSystem.content.ManagedSystem.AssociatedSystemProcessorConfiguration.SupportedPartitionProcessorCompatibilityModes."#text" | Where {$_ -match "POWER[0-9]*$"}) -replace "POWER",""
    foreach ($Gen in ($SupportedGens | sort)) {
        if ([int]$Gen -eq 9) {
            $SystemDTO.SupportedModes += "<span class='blue'>$($Gen)</span>"
        } elseif ([int]$Gen -eq 8) {
            $SystemDTO.SupportedModes += "<span class='purple'>$($Gen)</span>"
        } elseif ([int]$Gen -eq 7) {
            $SystemDTO.SupportedModes += "<span class='orange'>$($Gen)</span>"
        } else {
            $SystemDTO.SupportedModes += "<span class='green'>$($Gen)</span>"
        }
    }
    
    # ADD SYSTEM DTO TO OVERALL DTO
    $ManagedSystemsDTO += $SystemDTO
}

$ManagedSystemsDTO | ConvertTo-Json -Depth 3 -Compress | Out-File -Encoding utf8 -FilePath "C:\Dashboard\Data\ManagedSystems.json"
