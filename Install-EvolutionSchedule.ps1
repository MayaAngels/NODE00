# Install-EvolutionSchedule.ps1
$TaskName = "NODE00_AutoEvolution"
$ScriptPath = "$PWD\api-evolution.ps1"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"Invoke-RestMethod -Uri http://localhost:10000/api/evolve -Method POST`""
$Trigger = New-ScheduledTaskTrigger -Daily -At "00:00" -RepetitionInterval (New-TimeSpan -Hours 6) -RepetitionDuration (New-TimeSpan -Days 365)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
    Write-Host "✅ Auto-evolution scheduled (every 6 hours)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not create schedule. Run as Admin." -ForegroundColor Yellow
}
