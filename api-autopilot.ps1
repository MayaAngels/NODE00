# api-autopilot.ps1 - Handles approval queue + autopilot

$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/autopilot-data") {
    $data = @{
        apiKeys = @(
            @{name="Twitter"; status= if (Test-Path ".env" -and (Select-String -Path ".env" -Pattern "TWITTER_BEARER_TOKEN=" -Quiet)) { "✅ Configured" } else { "⚠️ Missing" }},
            @{name="MailChimp"; status= if (Test-Path ".env" -and (Select-String -Path ".env" -Pattern "MAILCHIMP_API_KEY=" -Quiet)) { "✅ Configured" } else { "⚠️ Missing" }},
            @{name="OpenAI"; status= if (Test-Path ".env" -and (Select-String -Path ".env" -Pattern "OPENAI_API_KEY=" -Quiet)) { "✅ Configured" } else { "⚠️ Missing" }}
        )
        pendingPosts = @()
        contentPlan = @(
            @{platform="Twitter"; time="09:00"; content="🚀 Good morning! Ready to automate your income? Ω-Conditions AI License is live → "; status="Pending"},
            @{platform="Twitter"; time="12:00"; content="💰 Did you know? Our AI optimizes prices in real-time. Currently at $61.10 → "; status="Pending"},
            @{platform="Twitter"; time="15:00"; content="🧠 7 Ω-conditions keep this system running WITHOUT collapse. Learn how → "; status="Pending"},
            @{platform="Twitter"; time="18:00"; content="📊 Today's revenue update. See live dashboard → "; status="Pending"},
            @{platform="Email"; time="10:00"; content="Newsletter: Weekly autonomous ecommerce insights"; status="Draft"},
            @{platform="Blog"; time="14:00"; content="Blog post: Why Fractal Homeostasis (λ) prevents system collapse"; status="Draft"}
        )
    }
    $data | ConvertTo-Json
}

if ($requestPath -eq "/api/enable-autopilot") {
    "AUTOPILOT_ENABLED=true" | Out-File -FilePath "AUTOPILOT.txt" -Encoding utf8
    Write-Host "✅ AUTOPILOT ENABLED" -ForegroundColor Green
}

if ($requestPath -eq "/api/download-report") {
    $report = Get-Content "AUTOPILOT-REPORT.txt" -ErrorAction SilentlyContinue
    if (-not $report) { $report = "No report available yet. Run content planner first." }
    Write-Output $report
}

Write-Host "✅ Autopilot API endpoints ready" -ForegroundColor Green
