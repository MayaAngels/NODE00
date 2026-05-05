# api-metrics.ps1 (updated)
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/metrics") {
    $metricsFile = "METRICS.json"
    $metrics = @{ totalRevenue = 0; todayRevenue = 0; lastUpdated = (Get-Date).ToString() }
    
    if (Test-Path $metricsFile) {
        $metrics = Get-Content $metricsFile | ConvertFrom-Json
    }
    
    # Also load transactions for weekly data
    $weeklyRevenue = @()
    $transactionsFile = "TRANSACTIONS.json"
    if (Test-Path $transactionsFile) {
        $transactions = Get-Content $transactionsFile | ConvertFrom-Json
        # Group by day for last 7 days
        for ($i = 6; $i -ge 0; $i--) {
            $date = (Get-Date).AddDays(-$i).ToString("yyyy-MM-dd")
            $dayRevenue = 0
            foreach ($tx in $transactions) {
                if ($tx.timestamp -match $date) {
                    $dayRevenue += $tx.amount
                }
            }
            $weeklyRevenue += @{ date = (Get-Date).AddDays(-$i).ToString("dd/MM"); revenue = [math]::Round($dayRevenue, 2) }
        }
    } else {
        for ($i = 6; $i -ge 0; $i--) {
            $weeklyRevenue += @{ date = (Get-Date).AddDays(-$i).ToString("dd/MM"); revenue = 0 }
        }
    }
    
    $result = @{
        totalRevenue = [math]::Round($metrics.totalRevenue, 2)
        todayRevenue = [math]::Round($metrics.todayRevenue, 2)
        targetRevenue = 47300
        weeklyRevenue = $weeklyRevenue
        hourlyRevenue = @()
        productsSold = @()
        lastUpdated = $metrics.lastUpdated
    }
    
    Write-Output ($result | ConvertTo-Json)
}
