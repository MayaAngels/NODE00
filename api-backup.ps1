# api-backup.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/backup-status") {
    $backupDir = "C:\Users\Maya\NewDigitalShop\BACKUPS"
    $backups = @()
    if (Test-Path $backupDir) {
        $backupList = Get-ChildItem -Path $backupDir -Directory | Where-Object { $_.Name -like "NODE00-BACKUP-*" } | Sort-Object CreationTime -Descending
        foreach ($backup in $backupList) {
            $size = [math]::Round((Get-ChildItem $backup.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
            $backups += @{
                name = $backup.Name
                date = $backup.CreationTime.ToString("yyyy-MM-dd HH:mm")
                size = $size
            }
        }
    }
    @{ backups = $backups; lastBackup = if ($backups.Count -gt 0) { $backups[0].date } else { "Nunca" } } | ConvertTo-Json
}

if ($requestPath -eq "/api/backup-now") {
    Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-File `"$PWD\AutoBackup.ps1`""
    @{ message = "Backup iniciado em segundo plano" } | ConvertTo-Json
}
