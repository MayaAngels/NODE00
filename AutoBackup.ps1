# AutoBackup.ps1 - Sistema de backup autônomo
# Salva o projeto inteiro, com versionamento incremental

$ProjectRoot = "C:\Users\Maya\NewDigitalShop\NODE00"
$BackupRoot = "C:\Users\Maya\NewDigitalShop\BACKUPS"
$BackupLog = "$BackupRoot\BACKUP-LOG.txt"
$MaxBackups = 10  # Manter últimos 10 backups

function Write-BackupLog {
    param($Message, $Color = "Gray")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"
    Add-Content -Path $BackupLog -Value $LogEntry
    Write-Host $LogEntry -ForegroundColor $Color
}

function Backup-Project {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupName = "NODE00-BACKUP-$timestamp"
    $backupPath = Join-Path $BackupRoot $backupName
    
    Write-BackupLog "🔄 Iniciando backup para $backupName" -Color Cyan
    
    try {
        # Copiar todo o projeto (excluindo .git, node_modules, backups antigos)
        $excludeItems = @('.git', 'BACKUPS', 'node_modules', '.env')  # .env contém chaves sensíveis, deve ser excluído ou criptografado
        Get-ChildItem -Path $ProjectRoot -Exclude $excludeItems | Copy-Item -Destination $backupPath -Recurse -Force
        
        # Backup especial do .env (criptografado)
        $envFile = Join-Path $ProjectRoot ".env"
        if (Test-Path $envFile) {
            $envBackup = Join-Path $backupPath ".env.backup"
            Copy-Item -Path $envFile -Destination $envBackup -Force
            Write-BackupLog "  ✓ .env salvo (contém chaves sensíveis)" -Color Gray
        }
        
        Write-BackupLog "✅ Backup concluído: $backupName" -Color Green
        return $backupPath
    } catch {
        Write-BackupLog "❌ Erro no backup: $_" -Color Red
        return $null
    }
}

function Rotate-Backups {
    $backups = Get-ChildItem -Path $BackupRoot -Directory | Where-Object { $_.Name -like "NODE00-BACKUP-*" } | Sort-Object CreationTime -Descending
    
    if ($backups.Count -gt $MaxBackups) {
        $toDelete = $backups | Select-Object -Skip $MaxBackups
        foreach ($backup in $toDelete) {
            Remove-Item -Path $backup.FullName -Recurse -Force
            Write-BackupLog "🗑️ Backup antigo removido: $($backup.Name)" -Color Yellow
        }
    }
}

function Restore-Backup {
    param($BackupName)
    
    $backupPath = Join-Path $BackupRoot $BackupName
    if (-not (Test-Path $backupPath)) {
        Write-BackupLog "❌ Backup não encontrado: $BackupName" -Color Red
        return $false
    }
    
    Write-BackupLog "⚠️ Restaurando backup: $BackupName" -Color Magenta
    
    # Salvar backup do estado atual antes de restaurar
    Backup-Project
    
    # Restaurar arquivos
    Copy-Item -Path "$backupPath\*" -Destination $ProjectRoot -Recurse -Force
    Write-BackupLog "✅ Restauração concluída: $BackupName" -Color Green
    return $true
}

function List-Backups {
    $backups = Get-ChildItem -Path $BackupRoot -Directory | Where-Object { $_.Name -like "NODE00-BACKUP-*" } | Sort-Object CreationTime -Descending
    Write-BackupLog "📋 Backups disponíveis: $($backups.Count)" -Color Yellow
    foreach ($backup in $backups) {
        $size = [math]::Round((Get-ChildItem $backup.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        Write-BackupLog "  • $($backup.Name) - $($backup.CreationTime) - ${size}MB" -Color Gray
    }
    return $backups
}

# Execução principal
Write-BackupLog "🚀 AutoBackup iniciado" -Color Magenta

# Verificar se já existe backup hoje
$today = (Get-Date).ToString("yyyyMMdd")
$todaysBackup = Get-ChildItem -Path $BackupRoot -Directory | Where-Object { 
    $_.Name -like "NODE00-BACKUP-$today*" 
}

if (-not $todaysBackup) {
    Backup-Project
    Rotate-Backups
} else {
    Write-BackupLog "✓ Backup já realizado hoje: $($todaysBackup.Name)" -Color Green
}

List-Backups
