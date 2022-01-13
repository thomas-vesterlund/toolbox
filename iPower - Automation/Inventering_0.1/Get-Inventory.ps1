# INCLUDE FUNCTIONS
try {
    . ("C:\Users\erik.bergkvist\Powershell\PowerInventering\Functions.ps1")
}
catch {
    Write-Host -ForegroundColor Magenta "Error while loading supporting PowerShell Scripts" 
}

Function Get-Inventory {
    Param (
        [Parameter(Mandatory=$true)][String]$Server,
        [Parameter(Mandatory=$true)][String]$User,
        [Parameter(Mandatory=$true)][String]$Password
    )

    # SET TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # GET CPW-DATA FROM FILE
    $SystemCPW = Import-Csv -Encoding UTF8 -Path "C:\Users\erik.bergkvist\Powershell\PowerInventering\SystemCPW.csv"

    # LOG ON, GET SESSION ID
    $Token = HmcLogon -Server $Server -User $User -Password $Password

    # GET LOGICAL PARTITIONS FROM HMC
    Write-Host -ForegroundColor Yellow "Getting Logical Partitions..." -NoNewline
    $LogicalPartitions = HmcRestGet -Token $Token -Uri "https://$($Server):12443/rest/api/uom/LogicalPartition"
    Write-Host -ForegroundColor Green "DONE!"

    # GET MANAGED SYSTEMS FROM HMC
    #Write-Host -ForegroundColor Yellow "Getting Managed Systems..." -NoNewline
    #$ManagedSystems = HmcRestGet -Token $Token -Uri "https://$($Server):12443/rest/api/uom/ManagedSystem"
    #Write-Host -ForegroundColor Green "DONE!"

    # LOG OFF API SESSION
    Start-Sleep -Seconds 1
    HmcLogoff -Server $Server -Token $Token

    # BUILD DTO
    $LogicalPartitionDTO = @()
    foreach ($Partition in $LogicalPartitions) {
        $LogicalPartition = @{
            UID = [string]($Partition.content.LogicalPartition.PartitionUUID."#text")
            UID2 = [string]($Partition.content.LogicalPartition.PartitionUUID."#text")
            CPUCoreQuantity = [decimal]$($Partition.content.LogicalPartition.PartitionProcessorConfiguration.CurrentSharedProcessorConfiguration.CurrentProcessingUnits."#text")
            Disks = @()
            FQDN = [string]($Partition.content.LogicalPartition.PartitionName."#text")
            InventoryName = [string]($Partition.content.LogicalPartition.PartitionName."#text")
            HostID = [string]($Partition.content.LogicalPartition.AssociatedManagedSystem.href) -replace "^.*/",""
            IPAddresses = @()
            PrimaryIpAddress = [string]""
            RAM = [int]($Partition.content.LogicalPartition.PartitionMemoryConfiguration.CurrentMemory."#text") * 1024 * 1024
            OSVersion = [string]($Partition.content.LogicalPartition.OperatingSystemVersion."#text")
        }
        $LogicalPartition.Add("CPUQuantity",[int](($SystemCPW | Where {$_.SystemUUID -eq $LogicalPartition.HostID}).ProcUnitCPW))
        $LogicalPartition.Add("CPUTotal",[int]($LogicalPartition.CPUQuantity * $LogicalPartition.CPUCoreQuantity))
        if (($Partition.content.LogicalPartition.PartitionState."#text") -match "running") {
            $LogicalPartition.Add("IsPoweredOn",$true)
        } else {
            $LogicalPartition.Add("IsPoweredOn",$false)
        }
        $LogicalPartitionDTO += $LogicalPartition
    }

    $Return = @{
        CloudCid = [int]0
        Servers = $LogicalPartitionDTO
        Datastores = @()
    }

    return $Return | ConvertTo-Json -Depth 5 -Compress
}

$Inventory = Get-Inventory -Server "pwrhmc02.ipower.local" -User "X" -Password "X"
$Inventory | Out-File -Encoding utf8 -FilePath "C:\Users\erik.bergkvist\Powershell\PowerInventering\iVirtual-IBM_Power_VM.json"



<#
link rel="SELF" href="https://pwrhmc01.ipower.local:12443/rest/api/uom/ManagedSystem/da0756bc-0ea4-33de-98ac-5b1965487b1b"/>
    <link rel="SELF" href="https://pwrhmc01.ipower.local:12443/rest/api/uom/ManagementConsole/6a5afa35-1dd6-379f-b4d0-ed7b88adb3de/ManagedSystem/da0756bc-0ea4-33de-98ac-5b1965487b1b/LogicalPartition"/>
    <link rel="MANAGEMENT_CONSOLE" href="https://pwrhmc01.ipower.local:12443/rest/api/uom/ManagementConsole/6a5afa35-1dd6-379f-b4d0-ed7b88adb3de"/>



https://pwrhmc01.ipower.local:12443/rest/api/uom/ManagementConsole/6a5afa35-1dd6-379f-b4d0-ed7b88adb3de/ManagedSystem/da0756bc-0ea4-33de-98ac-5b1965487b1b%22
https://pwrhmc01.ipower.local:12443/rest/api/uom/ManagedSystem/f51a52fe-388f-3514-b55f-f7e3fd2464d3/LogicalPartition


https://pwrhmc01.ipower.local:12443/rest/api/uom/LogicalPartition/60B8842B-3628-4572-AE78-5A056707F12A
<AssociatedManagedSystem kxe="false" kb="CUD" href="https://pwrhmc01.ipower.local:12443/rest/api/uom/ManagedSystem/f51a52fe-388f-3514-b55f-f7e3fd2464d3" rel="related"/>
#>