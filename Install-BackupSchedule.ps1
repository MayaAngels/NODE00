# Install-BackupSchedule.ps1 - CORRIGIDO
# Cria tarefa agendada para backup a cada 6 horas

$TaskName = "NODE00-AutoBackup"
$ScriptPath = "$PWD\AutoBackup.ps1"

# Verificar se está rodando como Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "❌ Execute este script como Administrador" -ForegroundColor Red
    exit
}

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$ScriptPath`""

# Criar trigger que repete a cada 6 horas (maneira correta)
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Hours 6) -RepetitionDuration (New-TimeSpan -Days 365)

$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartInterval (New-TimeSpan -Minutes 5)

try {
    # Remover tarefa antiga se existir
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    
    # Registrar nova tarefa
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
    Write-Host "✅ Backup schedule instalado com sucesso!" -ForegroundColor Green
    Write-Host "   A tarefa irá executar a cada 6 horas" -ForegroundColor Gray
    
    # Executar uma vez agora para testar
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "   Backup inicial disparado!" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erro ao instalar: $_" -ForegroundColor Red
}
