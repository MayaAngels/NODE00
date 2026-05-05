# api-device.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/detect-device") {
    $userAgent = $env:HTTP_USER_AGENT
    
    $device = @{
        type = "desktop"
        os = "unknown"
        browser = "unknown"
        isMobile = $false
        isTablet = $false
        isDesktop = $true
        recommendations = @()
    }
    
    # Detect mobile
    if ($userAgent -match "Mobile|Android|iPhone|iPad|iPod|BlackBerry|Windows Phone") {
        $device.isMobile = $true
        $device.isDesktop = $false
        $device.type = "mobile"
        
        if ($userAgent -match "iPhone|iPad|iPod") { $device.os = "iOS" }
        elseif ($userAgent -match "Android") { $device.os = "Android" }
        else { $device.os = "Mobile" }
        
        $device.recommendations = @(
            "Use simplified navigation",
            "Enable touch-friendly buttons",
            "Optimize images for mobile"
        )
    }
    
    # Detect tablet
    if ($userAgent -match "iPad|Tablet|Kindle|Silk") {
        $device.isTablet = $true
        $device.isMobile = $false
        $device.isDesktop = $false
        $device.type = "tablet"
        $device.recommendations = @(
            "Use 2-column layout",
            "Optimize touch targets"
        )
    }
    
    # Detect browser
    if ($userAgent -match "Chrome") { $device.browser = "Chrome" }
    elseif ($userAgent -match "Firefox") { $device.browser = "Firefox" }
    elseif ($userAgent -match "Safari") { $device.browser = "Safari" }
    elseif ($userAgent -match "Edge") { $device.browser = "Edge" }
    else { $device.browser = "Other" }
    
    Write-Output ($device | ConvertTo-Json)
}
