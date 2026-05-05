# Install-HourlyGuardianScan.ps1
# Creates a scheduled task to run Master Guardian Scanner every hour

$TaskName = "MasterGuardianHourlyScan"
$ScriptPath = "$PWD\MasterGuardianScanner.ps1"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Daily -At "00:00" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 365)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartInterval (New-TimeSpan -Minutes 5)

try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
    Write-Host "✅ Hourly scan scheduled successfully" -ForegroundColor Green
    Write-Host "   Task name: $TaskName" -ForegroundColor Gray
} catch {
    Write-Host "⚠️ Could not create scheduled task. Run as Administrator." -ForegroundColor Yellow
}

# Also create a startup task
$StartupTaskName = "MasterGuardianStartup"
$StartupTrigger = New-ScheduledTaskTrigger -AtStartup
try {
    Register-ScheduledTask -TaskName $StartupTaskName -Action $Action -Trigger $StartupTrigger -Principal $Principal -Settings $Settings -Force
    Write-Host "✅ Startup scan scheduled (runs at boot)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not create startup task." -ForegroundColor Yellow
}
