Import-Module "\\candfile03.candidator.se\System\Applications\Cendot\NetworkerAutomations\Automation.psm1"
Enable-Automation -ApiUrl "https://api.iplace.se/automation/v1" -ApiToken "Bearer 0995e493ca91ca5af7fed52a9e60d74d0812fc990efe90a5d4c3aa0d284ca385"

Invoke-Automation -Automation "Ny databas" -Script X:\iPlace\iPlace-DB\automations\new_db.ps1 -Variables @{name = "Test02"; sqlInstance = "isqldb01\node01,50001"}

Invoke-Automation -Automation "Ny databas" -Script X:\iPlace\iPlace-DB\automations\new_login.ps1 -Variables @{login = "isql\kerstin.lindberg"; sqlInstance = "isqldb01\node01,50001"}

Invoke-Automation -Automation "Ny databas" -Script X:\iPlace\iPlace-DB\automations\new_dbuser.ps1 -Variables @{login = "isql\kerstin.lindberg"; sqlInstance = "isqldb01\node01,50001"; database="Test01"}

Invoke-Automation -Automation "Ny databas" -Script X:\iPlace\iPlace-DB\automations\new_dbuserrolemember.ps1 -Variables @{login = "isql\kerstin.lindberg"; sqlInstance = "isqldb01\node01,50001"; database="Test02"; role = "db_owner"}
  
Invoke-Automation -Automation "Ny databas" -Script X:\iPlace\iPlace-DB\automations\new_instance.ps1 -Variables @{sqlInstance = "isqltest01\test55"}
  
Invoke-Automation -Automation "Ny databas" -Script X:\iPlace\iPlace-DB\automations\new_instance_unpatched.ps1 -Variables @{sqlInstance = "isqltest01\inst02"}