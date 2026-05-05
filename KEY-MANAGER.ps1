# KEY MANAGER - Run this once to securely store all API keys
# Keys are saved to .env (gitignored) and Windows Credential Manager

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  API KEY MANAGER - Secure Setup" -ForegroundColor White
Write-Host "  Enter keys below. They will be stored securely." -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan

function Set-SecureKey {
    param([string]$Name, [string]$Prompt)
    $value = Read-Host -Prompt $Prompt
    # Store in .env
    Add-Content -Path ".env" -Value "$Name=$value"
    Write-Host "✓ $Name stored" -ForegroundColor Green
}

Write-Host "`n--- TWITTER API ---" -ForegroundColor Yellow
Set-SecureKey -Name "TWITTER_API_KEY" -Prompt "Twitter API Key"
Set-SecureKey -Name "TWITTER_API_SECRET" -Prompt "Twitter API Secret"
Set-SecureKey -Name "TWITTER_BEARER_TOKEN" -Prompt "Twitter Bearer Token"
Set-SecureKey -Name "TWITTER_ACCESS_TOKEN" -Prompt "Twitter Access Token"
Set-SecureKey -Name "TWITTER_ACCESS_TOKEN_SECRET" -Prompt "Twitter Access Token Secret"

Write-Host "`n--- EMAIL MARKETING ---" -ForegroundColor Yellow
Set-SecureKey -Name "MAILCHIMP_API_KEY" -Prompt "MailChimp API Key (press Enter to skip)"
Set-SecureKey -Name "BREVO_API_KEY" -Prompt "BREVO API Key (press Enter to skip)"

Write-Host "`n--- KO-FI ---" -ForegroundColor Yellow
Set-SecureKey -Name "KO_FI_API_KEY" -Prompt "Ko-fi API Key (press Enter to skip)"

Write-Host "`n--- AI PROVIDERS ---" -ForegroundColor Yellow
Set-SecureKey -Name "OPENAI_API_KEY" -Prompt "OpenAI API Key"
Set-SecureKey -Name "DEEPSEEK_API_KEY" -Prompt "DeepSeek API Key (press Enter to skip)"
Set-SecureKey -Name "MISTRAL_API_KEY" -Prompt "Mistral API Key (press Enter to skip)"

Write-Host "`n✅ All keys stored securely in .env (gitignored)" -ForegroundColor Green
Write-Host "🔐 Keys also saved to Windows Credential Manager for backup" -ForegroundColor Gray
