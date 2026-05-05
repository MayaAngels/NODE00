# api-guardian.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/guardian-status") {
    $pendingCommits = git log origin/main..main --oneline 2>$null | Measure-Object | Select-Object -ExpandProperty Count
    $failedPushes = @()
    if (Test-Path "FAILED-PUSHES.json") {
        $failedPushes = Get-Content "FAILED-PUSHES.json" | ConvertFrom-Json
    }
    @{
        status = if (Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*GitGuardian*" }) { "✅ Active" } else { "⚠️ Not running" }
        lastPush = if (Test-Path "GUARDIAN-LOG.txt") { (Get-Content "GUARDIAN-LOG.txt" | Select-Object -Last 1) -replace '^\[|\].*', '' } else { "Never" }
        pendingCommits = $pendingCommits
        failedPushes = $failedPushes.Count
    } | ConvertTo-Json
}

if ($requestPath -eq "/api/retry-pushes") {
    Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-File `"$PWD\GitGuardian.ps1`" -RetryFailed"
    Write-Host "Retry initiated"
}
