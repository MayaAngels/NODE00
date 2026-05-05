# api-region.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/detect-region") {
    # Get client IP (from Render headers)
    $clientIp = $env:HTTP_X_FORWARDED_FOR
    if (-not $clientIp) { $clientIp = "0.0.0.0" }
    
    # Simple IP to country mapping (mock - in production use GeoIP)
    # For demo, check browser Accept-Language header
    $acceptLanguage = $env:HTTP_ACCEPT_LANGUAGE
    $countryCode = "US"  # default
    
    if ($acceptLanguage -match "pt") { $countryCode = "BR" }
    elseif ($acceptLanguage -match "es") { $countryCode = "SA" }
    elseif ($acceptLanguage -match "fr|de|it|nl") { $countryCode = "EU" }
    
    $config = Get-Content "region-config.json" | ConvertFrom-Json
    $region = $config.regions | Where-Object { $_.code -eq $countryCode }
    if (-not $region) { $region = $config.regions | Where-Object { $_.code -eq $config.defaultRegion } }
    
    $language = $config.languages.$($region.language)
    if (-not $language) { $language = $config.languages.en }
    
    $result = @{
        region = $region.code
        countryCode = $countryCode
        currency = $region.currency
        currencySymbol = $region.symbol
        language = $region.language
        pricingMultiplier = $region.pricingMultiplier
        translations = $language
        paymentMethods = $region.paymentMethods
    }
    
    Write-Output ($result | ConvertTo-Json)
}

if ($requestPath -eq "/api/region-pricing") {
    $body = $RequestBody | ConvertFrom-Json
    $basePrice = $body.basePrice
    $region = $body.region
    
    $config = Get-Content "region-config.json" | ConvertFrom-Json
    $regionData = $config.regions | Where-Object { $_.code -eq $region }
    if (-not $regionData) { $regionData = $config.regions | Where-Object { $_.code -eq $config.defaultRegion } }
    
    $adjustedPrice = [math]::Round($basePrice * $regionData.pricingMultiplier, 2)
    
    Write-Output "{ `"originalPrice`": $basePrice, `"adjustedPrice`": $adjustedPrice, `"currency`": `"$($regionData.currency)`", `"symbol`": `"$($regionData.symbol)`", `"multiplier`": $($regionData.pricingMultiplier) }"
}
