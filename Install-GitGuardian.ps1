# Install-GitGuardian.ps1 - Installs Git Guardian as a background service

Write-Host "Installing Git Guardian as background service..." -ForegroundColor Cyan

# Create scheduled task that runs on startup
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$PWD\GitGuardian.ps1`" -WindowStyle Hidden"
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "GitGuardian" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

Write-Host "✅ Git Guardian installed as scheduled task (runs at startup)" -ForegroundColor Green
Write-Host "   To start now: Start-ScheduledTask -TaskName 'GitGuardian'" -ForegroundColor Gray
