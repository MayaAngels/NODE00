# api-personalize.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/track-behavior") {
    $body = $RequestBody | ConvertFrom-Json
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    
    # Get or create user profile
    $behavior = Get-Content "behavior.json" | ConvertFrom-Json
    $userId = "anonymous"
    
    if ($token) {
        $sessions = Get-Content "sessions.json" | ConvertFrom-Json
        $userId = $sessions.$token
        if (-not $userId) { $userId = "anonymous" }
    }
    
    # Track event
    $event = @{
        userId = $userId
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        eventType = $body.eventType
        data = $body.data
        sessionId = $body.sessionId
    }
    
    $behavior.events += $event
    $behavior | ConvertTo-Json -Depth 10 | Out-File -FilePath "behavior.json" -Encoding utf8 -Force
    
    Write-Output '{ "success": true }'
}

if ($requestPath -eq "/api/recommendations") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    $body = $RequestBody | ConvertFrom-Json
    
    $behavior = Get-Content "behavior.json" | ConvertFrom-Json
    $userId = "anonymous"
    
    if ($token) {
        $sessions = Get-Content "sessions.json" | ConvertFrom-Json
        $userId = $sessions.$token
    }
    
    # Simple recommendation engine based on past behavior
    $userEvents = $behavior.events | Where-Object { $_.userId -eq $userId }
    
    # Count product views
    $productViews = @{}
    foreach ($event in $userEvents) {
        if ($event.eventType -eq "view_product") {
            $product = $event.data.product
            if ($productViews[$product]) { $productViews[$product]++ }
            else { $productViews[$product] = 1 }
        }
    }
    
    # Sort by views
    $sortedProducts = $productViews.Keys | Sort-Object { $productViews[$_] } -Descending
    
    # Default products
    $allProducts = @(
        @{ id = "license"; name = "Ω-Conditions AI License"; price = 47; category = "AI" },
        @{ id = "scale"; name = "Autonomous Scale Package"; price = 97; category = "scale" },
        @{ id = "report"; name = "Daily Revenue Report"; price = 29; category = "analytics" },
        @{ id = "enterprise"; name = "Full V3 System"; price = 199; category = "enterprise" }
    )
    
    # Generate recommendations
    $recommendations = @()
    if ($sortedProducts.Count -gt 0) {
        # User has history - recommend similar products
        $lastViewed = $sortedProducts[0]
        $recs = $allProducts | Where-Object { $_.id -ne $lastViewed } | Select-Object -First 3
        $recommendations = $recs
    } else {
        # New user - recommend popular products
        $recommendations = $allProducts | Select-Object -First 3
    }
    
    # Also recommend based on user plan
    if ($userId -ne "anonymous") {
        $users = Get-Content "users.json" | ConvertFrom-Json
        $user = $users.users | Where-Object { $_.id -eq $userId }
        if ($user -and $user.plan -eq "free") {
            $recommendations += @{ id = "upgrade"; name = "Upgrade to Pro"; price = 47; category = "upgrade" }
        }
    }
    
    $result = @{
        recommendations = $recommendations
        message = if ($recommendations.Count -gt 0) { "Based on your interests" } else { "Popular picks" }
    }
    
    Write-Output ($result | ConvertTo-Json)
}

if ($requestPath -eq "/api/user-insights") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    
    $behavior = Get-Content "behavior.json" | ConvertFrom-Json
    $userId = "anonymous"
    
    if ($token) {
        $sessions = Get-Content "sessions.json" | ConvertFrom-Json
        $userId = $sessions.$token
    }
    
    $userEvents = $behavior.events | Where-Object { $_.userId -eq $userId }
    
    $insights = @{
        totalVisits = ($userEvents | Where-Object { $_.eventType -eq "page_view" }).Count
        productsViewed = ($userEvents | Where-Object { $_.eventType -eq "view_product" }).Count
        lastActive = if ($userEvents.Count -gt 0) { $userEvents[-1].timestamp } else { "Never" }
        favoriteCategory = "AI Tools"
        engagementScore = [math]::Min(100, $userEvents.Count * 5)
    }
    
    Write-Output ($insights | ConvertTo-Json)
}
