# api-evolution.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/evolution-status") {
    $evolutionFile = "EVOLUTION.json"
    $evolution = @{
        generation = 0
        fitness = 0
        bestStrategy = "default"
        mutations = 0
        adaptations = @()
        lastEvolution = "Never"
    }
    
    if (Test-Path $evolutionFile) {
        $evolution = Get-Content $evolutionFile | ConvertFrom-Json
    }
    
    Write-Output ($evolution | ConvertTo-Json)
}

if ($requestPath -eq "/api/evolve") {
    # Load current metrics
    $metricsFile = "METRICS.json"
    $metrics = @{ totalRevenue = 0; todayRevenue = 0 }
    if (Test-Path $metricsFile) {
        $metrics = Get-Content $metricsFile | ConvertFrom-Json
    }
    
    # Load evolution state
    $evolutionFile = "EVOLUTION.json"
    $evolution = @{
        generation = 0
        fitness = 0
        bestStrategy = "default"
        mutations = @{}
        adaptations = @()
        lastEvolution = (Get-Date).ToString()
        strategyHistory = @()
    }
    
    if (Test-Path $evolutionFile) {
        $evolution = Get-Content $evolutionFile | ConvertFrom-Json
    }
    
    # Calculate fitness (0-100 based on revenue vs target)
    $dailyTarget = 47300 / 7  # ~6757
    $fitness = [math]::Min(100, [math]::Round(($metrics.totalRevenue / 47300) * 100, 1))
    
    # Define strategy parameters that can mutate
    $strategies = @{
        "pricing" = @{
            current = 47
            min = 29
            max = 199
            step = 5
        }
        "posting_frequency" = @{
            current = 4
            min = 1
            max = 12
            step = 1
        }
        "email_cadence" = @{
            current = 7
            min = 1
            max = 14
            step = 1
        }
        "discount_threshold" = @{
            current = 0.85
            min = 0.7
            max = 0.95
            step = 0.02
        }
    }
    
    # Check if fitness improved
    $improved = $fitness -gt $evolution.fitness
    $evolution.fitness = $fitness
    $evolution.generation++
    
    # If fitness improved, keep current strategy; else mutate
    $mutations = @{}
    if (-not $improved -and $evolution.generation -gt 1) {
        Write-Host "🧬 Fitness decreased ($($evolution.fitness)%) - Mutating strategies..." -ForegroundColor Yellow
        
        foreach ($strategy in $strategies.Keys) {
            $params = $strategies[$strategy]
            $direction = Get-Random -Minimum -1 -Maximum 2
            $newValue = $params.current + ($direction * $params.step)
            $newValue = [math]::Max($params.min, [math]::Min($params.max, $newValue))
            $mutations[$strategy] = @{ old = $params.current; new = [math]::Round($newValue, 2) }
            $strategies[$strategy].current = $newValue
        }
        
        $evolution.mutations = $mutations
        $evolution.adaptations += "Generation $($evolution.generation): Mutated due to fitness drop"
    } else {
        Write-Host "🧬 Fitness stable/improved ($($evolution.fitness)%) - Keeping strategies" -ForegroundColor Green
        $evolution.adaptations += "Generation $($evolution.generation): Fitness $($evolution.fitness)% - No mutation needed"
    }
    
    # Save evolved strategies to config
    $evolvedConfig = @{
        pricing = $strategies["pricing"].current
        posting_frequency = $strategies["posting_frequency"].current
        email_cadence = $strategies["email_cadence"].current
        discount_threshold = $strategies["discount_threshold"].current
        last_updated = (Get-Date).ToString()
        generation = $evolution.generation
    }
    $evolvedConfig | ConvertTo-Json | Out-File -FilePath "EVOLVED-CONFIG.json" -Encoding utf8 -Force
    
    # Record strategy in history
    $evolution.strategyHistory += @{
        generation = $evolution.generation
        fitness = $evolution.fitness
        timestamp = (Get-Date).ToString()
        strategies = $strategies
    }
    
    # Keep only last 20 entries
    if ($evolution.strategyHistory.Count -gt 20) {
        $evolution.strategyHistory = $evolution.strategyHistory[-20..-1]
    }
    
    $evolution.lastEvolution = (Get-Date).ToString()
    $evolution | ConvertTo-Json -Depth 10 | Out-File -FilePath $evolutionFile -Encoding utf8 -Force
    
    Write-Output (@{ success = $true; generation = $evolution.generation; fitness = $evolution.fitness; mutations = $mutations; improved = $improved } | ConvertTo-Json)
}

if ($requestPath -eq "/api/apply-evolution") {
    $body = $RequestBody | ConvertFrom-Json
    $strategy = $body.strategy
    $value = $body.value
    
    $evolvedConfig = Get-Content "EVOLVED-CONFIG.json" | ConvertFrom-Json
    $evolvedConfig.$strategy = $value
    $evolvedConfig | ConvertTo-Json | Out-File -FilePath "EVOLVED-CONFIG.json" -Encoding utf8 -Force
    
    Write-Output "{ `"success`": true, `"message`": `"Strategy $strategy updated to $value`" }"
}
