# Install-BackupSchedule.ps1
# Cria tarefa agendada para backup a cada 6 horas

$TaskName = "NODE00-AutoBackup"
$ScriptPath = "$PWD\AutoBackup.ps1"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Daily -At "00:00" -RepetitionInterval (New-TimeSpan -Hours 6) -RepetitionDuration (New-TimeSpan -Days 365)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
    Write-Host "✅ Backup schedule instalado (a cada 6 horas)" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Execute como Administrador para instalar o schedule" -ForegroundColor Yellow
}
