# api-scanner.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/scan-projects") {
    Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-File `"$PWD\MasterGuardianScanner.ps1`""
    Write-Output '{"message": "Scan started"}'
}

if ($requestPath -eq "/api/project-status") {
    if (Test-Path "PROJECTS-DATABASE.json") {
        $content = Get-Content "PROJECTS-DATABASE.json" -Raw
        Write-Output $content
    } else {
        Write-Output '{"projects": []}'
    }
}

if ($requestPath -eq "/api/heal-project") {
    $body = $requestBody | ConvertFrom-Json
    $repoPath = $body.repoPath
    $guardianPath = Join-Path $repoPath "CustomGuardian.ps1"
    if (Test-Path $guardianPath) {
        Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList "-File `"$guardianPath`""
    }
    Write-Output '{"message": "Healing started"}"
}
