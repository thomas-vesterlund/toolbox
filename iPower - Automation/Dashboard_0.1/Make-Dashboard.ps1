# GET DATA
$JsonFile = "C:\Dashboard\Data\ManagedSystems.json"
$MangedSystems = Get-Content -Raw -Path $JsonFile | ConvertFrom-Json
$DataTimeStamp = Get-Date (Get-Item $JsonFile).LastWriteTime -Format "yyyy-MM-dd HH:mm"
echo $DataTimeStamp

# CALCULATE TOTALS
[decimal]$TotalCPW = 0; $MangedSystems.CurrentAvailableCPW | ForEach-Object {$TotalCPW += [decimal]$_}
[decimal]$TotalMemory = 0; $MangedSystems.CurrentAvailableSystemMemoryGB | ForEach-Object {$TotalMemory += [decimal]$_}
[decimal]$TotalProcessorUnits = 0; $MangedSystems.CurrentAvailableSystemProcessorUnits | ForEach-Object {$TotalProcessorUnits += [decimal]$_}
[int]$TotalRunningLPars = 0; $MangedSystems.RunningPartitions | ForEach-Object {$TotalRunningLPars += [int]$_}
[int]$TotalNotActiveLPars = 0; $MangedSystems.NotActivePartitions | ForEach-Object {$TotalNotActiveLPars += [int]$_}

# CREATE SUMMARY ROW
$TotalRow = "" | select CurrentAvailableSystemProcessorUnits,SystemUUID,SystemName,ConfigurableSystemMemoryGB,ConfigurableCPW,CurrentAvailableCPW,CurrentAvailableSystemMemoryGB,ConfigurableSystemProcessorUnits,SystemAttention,RunningPartitions,NotActivePartitions,AttentionPartitions,PartitionSummary,SystemTypeModel,NotAvailablePartitions,SupportedModes
$TotalRow.SystemName = "$($DataTimeStamp)"
$TotalRow.CurrentAvailableCPW = $TotalCPW
$TotalRow.CurrentAvailableSystemMemoryGB = $TotalMemory
$TotalRow.CurrentAvailableSystemProcessorUnits = $TotalProcessorUnits
$TotalRow.PartitionSummary = "$($TotalRunningLPars) ($($TotalNotActiveLPars))"

# EXPORT TABLE TO HTML
$MangedSystems = $MangedSystems | sort SystemName
$MangedSystems += $TotalRow
$MangedSystems = $MangedSystems | select @{N="System Name";E={$_.SystemName}},@{N="Generation";E={$_.SupportedModes}},@{N="Type-Model";E={$_.SystemTypeModel}},@{N="Available Memory (GB)";E={$_.CurrentAvailableSystemMemoryGB}},@{N="Available Processor Units";E={$_.CurrentAvailableSystemProcessorUnits}},@{N="Available CPW";E={$_.CurrentAvailableCPW}},@{N="Attention";E={$_.SystemAttention}},@{N="LPAR Status";E={$_.PartitionSummary}}
$Meta = @{
    refresh = 60
}

($MangedSystems | ConvertTo-Html -Title "iPower Dashboard" -Head "<title>iPower Dashboard</title><meta http-equiv='refresh' content='120' />" -CssUri "managedsystems.css") -replace "&lt;","<" -replace "&gt;",">" -replace "&#39;","'"| Out-File -Encoding utf8 "C:\Dashboard\HTML\index.html"
