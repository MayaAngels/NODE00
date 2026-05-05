# api-webhook.ps1 - Recebe eventos do Stripe
param($RequestPath, $RequestBody)

if ($RequestPath -eq "/webhook/stripe") {
    $body = $RequestBody | ConvertFrom-Json
    $eventType = $body.type
    
    # Log received event
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Event: $eventType"
    Add-Content -Path "WEBHOOK-LOG.txt" -Value $logEntry
    
    if ($eventType -eq "checkout.session.completed") {
        $session = $body.data.object
        $amount = $session.amount_total / 100
        $product = $session.metadata.product_name
        $email = $session.customer_email
        $customerName = $session.customer_details.name
        $paymentStatus = $session.payment_status
        
        # Save transaction
        $transaction = @{
            id = $session.id
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            amount = $amount
            product = $product
            email = $email
            customerName = $customerName
            status = $paymentStatus
            type = "stripe"
        }
        
        $transactionsFile = "TRANSACTIONS.json"
        $existing = @()
        if (Test-Path $transactionsFile) {
            $existing = Get-Content $transactionsFile | ConvertFrom-Json
        }
        $existing += $transaction
        $existing | ConvertTo-Json -Depth 10 | Out-File -FilePath $transactionsFile -Encoding utf8 -Force
        
        # Update total revenue in metrics file
        $metricsFile = "METRICS.json"
        $metrics = @{ totalRevenue = 0; todayRevenue = 0; lastUpdated = (Get-Date).ToString() }
        if (Test-Path $metricsFile) {
            $metrics = Get-Content $metricsFile | ConvertFrom-Json
        }
        $metrics.totalRevenue += $amount
        $metrics.todayRevenue += $amount
        $metrics.lastUpdated = (Get-Date).ToString()
        $metrics | ConvertTo-Json | Out-File -FilePath $metricsFile -Encoding utf8 -Force
        
        # Send notification (optional)
        Write-Host "💰 NEW SALE: $product - `$$amount from $email" -ForegroundColor Green
        
        # If user is registered, update their subscription status
        if ($email) {
            $users = Get-Content "users.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
            if ($users) {
                for ($i = 0; $i -lt $users.users.Count; $i++) {
                    if ($users.users[$i].email -eq $email) {
                        if ($product -match "Pro|Enterprise|Scale") {
                            $users.users[$i].plan = "pro"
                            Write-Host "📈 User $email upgraded to Pro plan" -ForegroundColor Cyan
                        }
                        break
                    }
                }
                $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "users.json" -Encoding utf8 -Force
            }
        }
        
        Write-Output '{ "status": "success", "message": "Transaction recorded" }'
    }
    elseif ($eventType -eq "customer.subscription.created" -or $eventType -eq "customer.subscription.updated") {
        $subscription = $body.data.object
        $customerEmail = $subscription.customer_email
        $planId = $subscription.items.data[0].price.nickname
        
        # Update user subscription in users.json
        if ($customerEmail) {
            $users = Get-Content "users.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
            if ($users) {
                for ($i = 0; $i -lt $users.users.Count; $i++) {
                    if ($users.users[$i].email -eq $customerEmail) {
                        $users.users[$i].plan = if ($planId -match "pro") { "pro" } elseif ($planId -match "enterprise") { "enterprise" } else { "free" }
                        $users.users[$i].subscription_status = "active"
                        $users.users[$i].subscription_plan = $planId
                        break
                    }
                }
                $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "users.json" -Encoding utf8 -Force
                Write-Host "📋 Subscription updated for $customerEmail: $planId" -ForegroundColor Cyan
            }
        }
        
        Write-Output '{ "status": "success", "message": "Subscription updated" }'
    }
    else {
        Write-Output '{ "status": "ignored", "message": "Event type not handled" }'
    }
}
