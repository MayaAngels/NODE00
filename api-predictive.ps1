# api-predictive.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/predict-revenue") {
    # Load historical transactions
    $transactionsFile = "TRANSACTIONS.json"
    $dailyRevenue = @{}
    
    if (Test-Path $transactionsFile) {
        $transactions = Get-Content $transactionsFile | ConvertFrom-Json
        foreach ($tx in $transactions) {
            $date = ($tx.timestamp -split " ")[0]
            if ($dailyRevenue[$date]) { $dailyRevenue[$date] += $tx.amount }
            else { $dailyRevenue[$date] = $tx.amount }
        }
    }
    
    # Get last 7 days of revenue
    $last7Days = @()
    $values = @()
    for ($i = 6; $i -ge 0; $i--) {
        $date = (Get-Date).AddDays(-$i).ToString("yyyy-MM-dd")
        $revenue = if ($dailyRevenue[$date]) { $dailyRevenue[$date] } else { 0 }
        $last7Days += $revenue
        $values += $revenue
    }
    
    # Simple linear regression for prediction
    $n = $values.Count
    if ($n -gt 1) {
        $sumX = 0; $sumY = 0; $sumXY = 0; $sumX2 = 0
        for ($i = 0; $i -lt $n; $i++) {
            $sumX += $i
            $sumY += $values[$i]
            $sumXY += $i * $values[$i]
            $sumX2 += $i * $i
        }
        $slope = ($n * $sumXY - $sumX * $sumY) / ($n * $sumX2 - $sumX * $sumX)
        $intercept = ($sumY - $slope * $sumX) / $n
        
        # Predict next 7 days
        $predictions = @()
        $totalPredicted = 0
        for ($i = 1; $i -le 7; $i++) {
            $predicted = [math]::Max(0, $intercept + $slope * ($n + $i - 1))
            $predictions += @{
                day = (Get-Date).AddDays($i).ToString("dd/MM")
                revenue = [math]::Round($predicted, 2)
            }
            $totalPredicted += $predicted
        }
        
        # Calculate confidence (based on R-squared approximation)
        $meanY = $sumY / $n
        $ssTotal = 0; $ssResidual = 0
        for ($i = 0; $i -lt $n; $i++) {
            $ssTotal += ($values[$i] - $meanY) * ($values[$i] - $meanY)
            $predicted = $intercept + $slope * $i
            $ssResidual += ($values[$i] - $predicted) * ($values[$i] - $predicted)
        }
        $rSquared = if ($ssTotal -gt 0) { 1 - ($ssResidual / $ssTotal) } else { 0 }
        $confidence = [math]::Round($rSquared * 100, 1)
        
        # Detect trend
        $trend = if ($slope -gt 5) { "🚀 Strong Upward" }
        elseif ($slope -gt 1) { "📈 Upward" }
        elseif ($slope -lt -5) { "📉 Strong Downward" }
        elseif ($slope -lt -1) { "📉 Downward" }
        else { "➡️ Stable" }
        
        $result = @{
            predictions = $predictions
            totalPredicted7Days = [math]::Round($totalPredicted, 2)
            trend = $trend
            confidence = $confidence
            last7Days = $last7Days
            slope = [math]::Round($slope, 2)
        }
        
        Write-Output ($result | ConvertTo-Json)
    } else {
        Write-Output '{ "error": "Insufficient data for prediction" }'
    }
}

if ($requestPath -eq "/api/anomaly-detection") {
    $transactionsFile = "TRANSACTIONS.json"
    if (-not (Test-Path $transactionsFile)) {
        Write-Output '{ "anomalies": [], "message": "No transactions yet" }'
        exit
    }
    
    $transactions = Get-Content $transactionsFile | ConvertFrom-Json
    
    # Group by hour for last 24 hours
    $hourlyRevenue = @{}
    $now = Get-Date
    for ($i = 0; $i -lt 24; $i++) {
        $hour = $now.AddHours(-$i).ToString("yyyy-MM-dd HH:00")
        $hourlyRevenue[$hour] = 0
    }
    
    foreach ($tx in $transactions) {
        $txHour = ($tx.timestamp -replace ":[0-9]{2}$", ":00")
        if ($hourlyRevenue.ContainsKey($txHour)) {
            $hourlyRevenue[$txHour] += $tx.amount
        }
    }
    
    # Calculate statistics
    $values = $hourlyRevenue.Values | Where-Object { $_ -gt 0 }
    if ($values.Count -gt 0) {
        $avg = ($values | Measure-Object -Average).Average
        $stdDev = 0
        foreach ($v in $values) { $stdDev += [math]::Pow($v - $avg, 2) }
        $stdDev = [math]::Sqrt($stdDev / $values.Count)
        $threshold = $avg + 2 * $stdDev
        
        # Detect anomalies
        $anomalies = @()
        foreach ($hour in $hourlyRevenue.Keys) {
            $revenue = $hourlyRevenue[$hour]
            if ($revenue -gt $threshold -and $revenue -gt 0) {
                $anomalies += @{
                    hour = $hour
                    revenue = $revenue
                    type = "spike"
                    message = "Unusual spike detected: `$$revenue in one hour"
                }
            }
        }
        
        Write-Output (@{ anomalies = $anomalies; avgHourly = [math]::Round($avg, 2); threshold = [math]::Round($threshold, 2) } | ConvertTo-Json)
    } else {
        Write-Output '{ "anomalies": [], "message": "Insufficient data" }'
    }
}

if ($requestPath -eq "/api/revenue-alerts") {
    $metricsFile = "METRICS.json"
    $alerts = @()
    
    if (Test-Path $metricsFile) {
        $metrics = Get-Content $metricsFile | ConvertFrom-Json
        
        # Check against target (47,300 in 7 days = ~6,757 per day)
        $dailyTarget = 47300 / 7
        if ($metrics.todayRevenue -lt $dailyTarget * 0.5 -and (Get-Date).Hour -gt 12) {
            $alerts += @{
                type = "warning"
                message = "Today's revenue is below 50% of daily target"
                action = "Consider running a promotion"
            }
        }
        
        # Check if close to target
        $daysRemaining = 7 - (Get-Date).DayOfWeek
        $neededDaily = [math]::Max(0, (47300 - $metrics.totalRevenue) / $daysRemaining)
        if ($neededDaily -gt $dailyTarget * 1.5) {
            $alerts += @{
                type = "alert"
                message = "Need `$$neededDaily per day to hit target"
                action = "Increase marketing efforts"
            }
        }
    }
    
    Write-Output (@{ alerts = $alerts; timestamp = (Get-Date).ToString() } | ConvertTo-Json)
}
