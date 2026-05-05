# Adicionar ao api-auth.ps1 existente

if ($RequestPath -eq "/api/plans") {
    $plans = Get-Content "subscription-plans.json" | ConvertFrom-Json
    Write-Output ($plans | ConvertTo-Json)
}

if ($RequestPath -eq "/api/user-plan") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    $sessions = Get-Content "sessions.json" | ConvertFrom-Json
    $userId = $sessions.$token
    
    $users = Get-Content "users.json" | ConvertFrom-Json
    $user = $users.users | Where-Object { $_.id -eq $userId }
    $plan = if ($user) { $user.plan } else { "free" }
    
    Write-Output "{ `"plan`": `"$plan`" }"
}

if ($RequestPath -eq "/api/create-subscription") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    $body = $RequestBody | ConvertFrom-Json
    $planId = $body.plan
    
    $plans = Get-Content "subscription-plans.json" | ConvertFrom-Json
    $plan = $plans.plans | Where-Object { $_.id -eq $planId }
    
    if ($plan -and $plan.price -gt 0) {
        # Simulate Stripe checkout (real implementation would call Stripe API)
        $checkoutUrl = "https://node00-omega.onrender.com/success.html?plan=$planId"
        Write-Output "{ `"url`": `"$checkoutUrl`" }"
    } else {
        Write-Output "{ `"error`": `"Invalid plan`" }"
    }
}

if ($RequestPath -eq "/api/downgrade-plan") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    $sessions = Get-Content "sessions.json" | ConvertFrom-Json
    $userId = $sessions.$token
    
    $body = $RequestBody | ConvertFrom-Json
    $newPlan = $body.plan
    
    $users = Get-Content "users.json" | ConvertFrom-Json
    for ($i = 0; $i -lt $users.users.Count; $i++) {
        if ($users.users[$i].id -eq $userId) {
            $users.users[$i].plan = $newPlan
            break
        }
    }
    
    $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "users.json" -Encoding utf8 -Force
    Write-Output "{ `"success`": true }"
}
