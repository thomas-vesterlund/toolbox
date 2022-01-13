 param (
        [parameter(mandatory=$true)][string]$sqlInstance
   )

$env:PSModulePath = $env:PSModulePath + ";C:\Program Files\WindowsPowerShell\Modules"


#HKEY_LOCAL_MACHINE\Software\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb DWORD ProtectionPolicy registry entry to 1
install-dbainstance -sqlinstance $sqlinstance -version 2019 -Feature Engine,FullText -path g: -SaveConfiguration:$true -PerformVolumeMaintenanceTasks:$true -UpdateSourcePath c:\patches -Confirm:$false -EnableException

#install-dbainstance -sqlinstance $sqlinstance -version 2019 -Feature Engine,FullText -path g: -SaveConfiguration:$true -PerformVolumeMaintenanceTasks:$true -Confirm:$false -EnableException

#Update-DbaInstance -ComputerName SQL1 -Version SP3 -Path c:\patches