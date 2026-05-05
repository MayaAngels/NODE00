# api-subscribe.ps1
param($RequestPath)

if ($RequestPath -eq "/api/subscribe") {
    $body = Get-Content "request-body.json" -Raw | ConvertFrom-Json
    $email = $body.email
    
    # Validação básica
    if ($email -notmatch '^[^@]+@[^@]+\.[^@]+$') {
        Write-Output '{ "success": false, "message": "Email inválido" }'
        exit
    }
    
    $mailchimpKey = (Get-Content ".env" | Select-String "MAILCHIMP_API_KEY=").ToString().Split('=')[1]
    
    if ($mailchimpKey -and $mailchimpKey -ne "demo") {
        # MailChimp real
        $server = ($mailchimpKey -split "-")[1]
        $listId = "seu-list-id-aqui"  # Será configurado manualmente
        
        $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("anystring:$mailchimpKey"))
        $headers = @{
            "Authorization" = "Basic $auth"
            "Content-Type" = "application/json"
        }
        
        $subscriberData = @{
            email_address = $email
            status = "subscribed"
        } | ConvertTo-Json
        
        try {
            $url = "https://$server.api.mailchimp.com/3.0/lists/$listId/members"
            Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $subscriberData
            Write-Output '{ "success": true, "message": "Inscrito com sucesso!" }'
        } catch {
            Write-Output '{ "success": false, "message": "Erro no MailChimp. Tente novamente." }'
        }
    } else {
        # Modo demo - salva localmente
        $leadsFile = "LEADS.txt"
        Add-Content -Path $leadsFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $email"
        Write-Output '{ "success": true, "message": "Inscrição salva (modo demo)!" }'
    }
}
