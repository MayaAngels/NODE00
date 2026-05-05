# api-handler.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -like "/api/create-checkout") {
    .\api-checkout.ps1
} elseif ($requestPath -like "/api/guardian-status") {
    .\api-guardian.ps1
} elseif ($requestPath -like "/api/scan-projects") {
    .\api-scanner.ps1
} elseif ($requestPath -like "/api/dashboard") {
    .\api.ps1
} else {
    Write-Output '{"error": "Unknown API endpoint"}'
}
