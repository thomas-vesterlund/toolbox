$i = 1
while ($i -le 50) {
    clear
    Write-Host -ForegroundColor Cyan "Loop Counter: $($i)/50"
    C:\Dashboard\Get-DashboardData.ps1; C:\Dashboard\Make-Dashboard.ps1
    Start-Sleep -Seconds 120
    $i++
}
