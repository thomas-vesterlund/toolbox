 param (
    [parameter(mandatory=$true)][string]$login,
    [parameter(mandatory=$true)][string]$sqlInstance
)

$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Modules"

New-DbaLogin -sqlinstance $sqlInstance -name $login -EnableException