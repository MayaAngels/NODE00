# api-checkout.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/create-checkout") {
    $body = Get-Content "request-body.json" -Raw | ConvertFrom-Json
    $amount = $body.amount
    $productName = $body.product.name
    $productDescription = $body.product.description
    
    $stripeSecret = (Get-Content ".env" | Select-String "STRIPE_SECRET_KEY=").ToString().Split('=')[1]
    $credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${stripeSecret}:"))
    
    $bodyParams = @{
        success_url = "https://node00-omega.onrender.com/success.html"
        cancel_url = "https://node00-omega.onrender.com/"
        payment_method_types = @("card")
        line_items = @(
            @{
                price_data = @{
                    currency = "usd"
                    product_data = @{
                        name = $productName
                        description = $productDescription
                    }
                    unit_amount = $amount * 100
                }
                quantity = 1
            }
        )
        mode = "payment"
    }
    
    $bodyJson = $bodyParams | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Basic $credentials"
        "Content-Type" = "application/json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.stripe.com/v1/checkout/sessions" -Method Post -Headers $headers -Body $bodyJson
        Write-Output "{ `"url`": `"$($response.url)`" }"
    } catch {
        Write-Output "{ `"error`": `"$($_.Exception.Message)`" }"
    }
}
