 param (
    [parameter(mandatory=$true)][string]$login,
    [parameter(mandatory=$true)][string]$sqlInstance,
    [parameter(mandatory=$true)][string]$database,
    [parameter(mandatory=$true)][string]$role
)

$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Modules"

Add-DbaDbRoleMember -sqlinstance $sqlInstance -database $database -User $login -Role $Role -Confirm:$false -EnableException