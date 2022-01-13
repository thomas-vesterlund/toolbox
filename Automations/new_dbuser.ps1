 param (
    [parameter(mandatory=$true)][string]$login,
    [parameter(mandatory=$true)][string]$sqlInstance,
    [parameter(mandatory=$true)][string]$database
)

$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Modules"

New-DbaDBUser -sqlinstance $sqlInstance -database $database -username $login -EnableException