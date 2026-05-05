# api.ps1 - Simple dashboard API
$response = @{
    totalRevenue = 47300 * (Get-Random -Minimum 0.0 -Maximum 0.3)  # Mock until real data
    aiPrice = 61.10
    aiPick = "Autonomous Scale Package"
    demand = 0.82
    omegaHealth = @{
        lambda = $true; kappa = $true; tau = $true; gamma = $true
        theta = $true; sigma = $true; alpha = $true
    }
    hourly = @()
}
for ($i=0; $i -lt 24; $i++) {
    $response.hourly += @{
        hour = "$i`:00"
        visitors = Get-Random -Minimum 50 -Maximum 500
        sales = Get-Random -Minimum 0 -Maximum 20
        revenue = Get-Random -Minimum 0 -Maximum 500
        conv = "$(Get-Random -Minimum 1 -Maximum 8)%"
        aov = Get-Random -Minimum 30 -Maximum 80
    }
}
$response | ConvertTo-Json
