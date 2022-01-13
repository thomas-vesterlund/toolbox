 param (
    [parameter(mandatory=$true)][string]$name,
    [parameter(mandatory=$true)][string]$sqlInstance
)


Import-Module "C:\Program Files\WindowsPowerShell\Modules\dbatools\1.0.104\dbatools.psm1"

New-DbaDatabase -sqlinstance $sqlInstance -name $name -EnableException