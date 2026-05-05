# api-auth.ps1
param($RequestPath, $RequestBody)

if ($RequestPath -eq "/api/register") {
    $body = $RequestBody | ConvertFrom-Json
    $email = $body.email
    $name = $body.name
    $password = $body.password
    
    # Load existing users
    $users = Get-Content "users.json" | ConvertFrom-Json
    
    # Check if email exists
    $exists = $users.users | Where-Object { $_.email -eq $email }
    if ($exists) {
        Write-Output '{ "success": false, "message": "Email already registered" }'
        exit
    }
    
    # Create new user
    $newUser = @{
        id = "user_" + [System.Guid]::NewGuid().ToString().Substring(0, 8)
        email = $email
        name = $name
        password_hash = $password
        created_at = (Get-Date).ToString("yyyy-MM-dd")
        plan = "free"
        preferences = @{
            theme = "dark"
            language = "en"
            notifications = $true
        }
    }
    
    $users.users += $newUser
    $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "users.json" -Encoding utf8 -Force
    
    Write-Output '{ "success": true, "message": "Account created successfully" }'
}

if ($RequestPath -eq "/api/login") {
    $body = $RequestBody | ConvertFrom-Json
    $email = $body.email
    $password = $body.password
    
    $users = Get-Content "users.json" | ConvertFrom-Json
    $user = $users.users | Where-Object { $_.email -eq $email -and $_.password_hash -eq $password }
    
    if ($user) {
        $token = [System.Guid]::NewGuid().ToString()
        
        # Save session
        $sessions = @{}
        if (Test-Path "sessions.json") {
            $sessions = Get-Content "sessions.json" | ConvertFrom-Json
        }
        $sessions | Add-Member -NotePropertyName $token -NotePropertyValue $user.id -Force
        $sessions | ConvertTo-Json | Out-File -FilePath "sessions.json" -Encoding utf8 -Force
        
        Write-Output "{ `"success`": true, `"token`": `"$token`", `"user`": { `"name`": `"$($user.name)`", `"email`": `"$($user.email)`", `"plan`": `"$($user.plan)`" } }"
    } else {
        Write-Output '{ "success": false, "message": "Invalid email or password" }'
    }
}

if ($RequestPath -eq "/api/verify-session") {
    $headers = $env:HTTP_AUTHORIZATION
    $token = $headers -replace "Bearer ", ""
    
    $sessions = Get-Content "sessions.json" | ConvertFrom-Json
    $userId = $sessions.$token
    
    if ($userId) {
        $users = Get-Content "users.json" | ConvertFrom-Json
        $user = $users.users | Where-Object { $_.id -eq $userId }
        Write-Output "{ `"valid`": true, `"user`": { `"name`": `"$($user.name)`", `"email`": `"$($user.email)`", `"plan`": `"$($user.plan)`" } }"
    } else {
        Write-Output '{ "valid": false }'
    }
}
# Adicionar ao api-auth.ps1 existente

if ($RequestPath -eq "/api/update-profile") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    $sessions = Get-Content "sessions.json" | ConvertFrom-Json
    $userId = $sessions.$token
    
    if (-not $userId) {
        Write-Output '{ "success": false, "message": "Invalid session" }'
        exit
    }
    
    $body = $RequestBody | ConvertFrom-Json
    $users = Get-Content "users.json" | ConvertFrom-Json
    
    for ($i = 0; $i -lt $users.users.Count; $i++) {
        if ($users.users[$i].id -eq $userId) {
            $users.users[$i].name = $body.name
            $users.users[$i].bio = $body.bio
            break
        }
    }
    
    $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "users.json" -Encoding utf8 -Force
    Write-Output '{ "success": true, "message": "Profile updated" }'
}

if ($RequestPath -eq "/api/save-preferences") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    $sessions = Get-Content "sessions.json" | ConvertFrom-Json
    $userId = $sessions.$token
    
    if (-not $userId) {
        Write-Output '{ "success": false, "message": "Invalid session" }'
        exit
    }
    
    $body = $RequestBody | ConvertFrom-Json
    $users = Get-Content "users.json" | ConvertFrom-Json
    
    for ($i = 0; $i -lt $users.users.Count; $i++) {
        if ($users.users[$i].id -eq $userId) {
            $users.users[$i].preferences = @{
                theme = $body.theme
                language = $body.language
                notifications = $body.notifications
            }
            break
        }
    }
    
    $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "users.json" -Encoding utf8 -Force
    Write-Output '{ "success": true, "message": "Preferences saved" }'
}

if ($RequestPath -eq "/api/change-password") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    $sessions = Get-Content "sessions.json" | ConvertFrom-Json
    $userId = $sessions.$token
    
    if (-not $userId) {
        Write-Output '{ "success": false, "message": "Invalid session" }'
        exit
    }
    
    $body = $RequestBody | ConvertFrom-Json
    $users = Get-Content "users.json" | ConvertFrom-Json
    
    for ($i = 0; $i -lt $users.users.Count; $i++) {
        if ($users.users[$i].id -eq $userId) {
            $users.users[$i].password_hash = $body.password
            break
        }
    }
    
    $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "users.json" -Encoding utf8 -Force
    Write-Output '{ "success": true, "message": "Password changed" }'
}

if ($RequestPath -eq "/api/delete-account") {
    $token = $env:HTTP_AUTHORIZATION -replace "Bearer ", ""
    $sessions = Get-Content "sessions.json" | ConvertFrom-Json
    $userId = $sessions.$token
    
    if (-not $userId) {
        Write-Output '{ "success": false, "message": "Invalid session" }'
        exit
    }
    
    $users = Get-Content "users.json" | ConvertFrom-Json
    $users.users = $users.users | Where-Object { $_.id -ne $userId }
    $users | ConvertTo-Json -Depth 10 | Out-File -FilePath "users.json" -Encoding utf8 -Force
    
    # Remove session
    $sessions.PSObject.Properties.Remove($token)
    $sessions | ConvertTo-Json | Out-File -FilePath "sessions.json" -Encoding utf8 -Force
    
    Write-Output '{ "success": true, "message": "Account deleted" }'
}
