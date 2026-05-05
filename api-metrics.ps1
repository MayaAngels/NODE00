# api-metrics.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/metrics") {
    # Carregar receita do Stripe (simulação por enquanto)
    $stripeSecret = (Get-Content ".env" -ErrorAction SilentlyContinue | Select-String "STRIPE_SECRET_KEY=").ToString().Split('=')[1]
    
    $totalRevenue = 0
    $todayRevenue = 0
    $weeklyRevenue = @()
    $hourlyRevenue = @()
    
    if ($stripeSecret -and $stripeSecret -ne "demo") {
        # Aqui faria chamada real à API do Stripe
        # Por enquanto, dados mockados para demonstração
        $totalRevenue = 47300 * (Get-Random -Minimum 0.0 -Maximum 0.05)
        $todayRevenue = $totalRevenue * 0.2
    } else {
        # Mock data para teste
        $totalRevenue = [math]::Round((Get-Random -Minimum 0 -Maximum 5000), 2)
        $todayRevenue = [math]::Round((Get-Random -Minimum 0 -Maximum 1000), 2)
    }
    
    # Dados para gráficos semanais
    for ($i = 6; $i -ge 0; $i--) {
        $date = (Get-Date).AddDays(-$i).ToString("dd/MM")
        $revenue = [math]::Round((Get-Random -Minimum 0 -Maximum ($totalRevenue / 7)), 2)
        $weeklyRevenue += @{ date = $date; revenue = $revenue }
    }
    
    # Dados para gráfico horário
    for ($i = 0; $i -lt 24; $i++) {
        $hour = "{0:D2}:00" -f $i
        $revenue = [math]::Round((Get-Random -Minimum 0 -Maximum 500), 2)
        $hourlyRevenue += @{ hour = $hour; revenue = $revenue }
    }
    
    $result = @{
        totalRevenue = $totalRevenue
        todayRevenue = $todayRevenue
        targetRevenue = 47300
        weeklyRevenue = $weeklyRevenue
        hourlyRevenue = $hourlyRevenue
        productsSold = @(
            @{ name = "Ω-Conditions AI License"; revenue = $totalRevenue * 0.4; quantity = [math]::Round($totalRevenue * 0.4 / 47) },
            @{ name = "Autonomous Scale Package"; revenue = $totalRevenue * 0.35; quantity = [math]::Round($totalRevenue * 0.35 / 97) },
            @{ name = "Daily Revenue Report"; revenue = $totalRevenue * 0.15; quantity = [math]::Round($totalRevenue * 0.15 / 29) },
            @{ name = "Full V3 System"; revenue = $totalRevenue * 0.10; quantity = [math]::Round($totalRevenue * 0.10 / 199) }
        )
    }
    
    $result | ConvertTo-Json
}
