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
} } elseif ($requestPath -like "/api/subscribe") {
    .\api-subscribe.ps1
} } elseif ($requestPath -like "/api/blog-posts") {
    .\api-blog.ps1
} } elseif ($requestPath -like "/api/metrics") {
    .\api-metrics.ps1
} } elseif ($requestPath -like "/api/backup-status") {
    .\api-backup.ps1
} elseif ($requestPath -like "/api/backup-now") {
    .\api-backup.ps1
} } elseif ($requestPath -like "/api/login") {
    .\api-auth.ps1
} elseif ($requestPath -like "/api/register") {
    .\api-auth.ps1
} elseif ($requestPath -like "/api/verify-session") {
    .\api-auth.ps1
} } elseif ($requestPath -like "/api/update-profile") {
    .\api-auth.ps1
} elseif ($requestPath -like "/api/save-preferences") {
    .\api-auth.ps1
} elseif ($requestPath -like "/api/change-password") {
    .\api-auth.ps1
} elseif ($requestPath -like "/api/delete-account") {
    .\api-auth.ps1
} } elseif ($requestPath -like "/api/plans") {
    .\api-subscription.ps1
} elseif ($requestPath -like "/api/user-plan") {
    .\api-subscription.ps1
} elseif ($requestPath -like "/api/create-subscription") {
    .\api-subscription.ps1
} elseif ($requestPath -like "/api/downgrade-plan") {
    .\api-subscription.ps1
} } elseif ($requestPath -like "/api/detect-region") {
    .\api-region.ps1
} elseif ($requestPath -like "/api/region-pricing") {
    .\api-region.ps1
} } elseif ($requestPath -like "/api/detect-device") {
    .\api-device.ps1
} else {
    Write-Output '{"error": "Unknown API endpoint"}'
}









