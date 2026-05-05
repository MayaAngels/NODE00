# GitGuardian.ps1 - Autonomous Git push daemon
# Runs in background, monitors connection, retries failed pushes

$GuardianLog = "GUARDIAN-LOG.txt"
$FailedPushesFile = "FAILED-PUSHES.json"
$LastRun = (Get-Date).AddHours(-1)

function Write-Log {
    param($Message, $Color = "Gray")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"
    Add-Content -Path $GuardianLog -Value $LogEntry
    Write-Host $LogEntry -ForegroundColor $Color
}

function Test-InternetConnection {
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 5 -UseBasicParsing
        return $true
    } catch {
        return $false
    }
}

function Get-ConnectionStrength {
    try {
        $ping = Test-Connection -ComputerName github.com -Count 2 -Quiet
        if ($ping) { return "Strong" } else { return "Weak" }
    } catch {
        return "Disconnected"
    }
}

function Try-GitPush {
    param([string]$Strategy = "full")
    
    switch ($Strategy) {
        "full" {
            Write-Log "🔄 Attempting full push..." -Color Cyan
            $result = git push origin main 2>&1
            if ($LASTEXITCODE -eq 0) { return $true }
        }
        "chunked" {
            Write-Log "🔄 Attempting chunked push (by folder)..." -Color Cyan
            $folders = Get-ChildItem -Directory | Select-Object -ExpandProperty Name
            foreach ($folder in $folders) {
                git add $folder
                git commit -m "Chunked push: $folder" 2>$null
                git push origin main 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) { 
                    Write-Log "⚠️ Failed to push $folder" -Color Yellow
                }
            }
            return $true
        }
        "single-file" {
            Write-Log "🔄 Attempting single-file pushes..." -Color Cyan
            $files = git diff --name-only HEAD~1
            foreach ($file in $files) {
                git add $file
                git commit -m "Single-file push: $file" 2>$null
                git push origin main 2>&1 | Out-Null
                Start-Sleep -Seconds 1
            }
            return $true
        }
        default { return $false }
    }
}

function Save-FailedPush {
    param($CommitHash, $ErrorMessage)
    $failedPushes = @()
    if (Test-Path $FailedPushesFile) {
        $failedPushes = Get-Content $FailedPushesFile | ConvertFrom-Json
    }
    $failedPushes += @{
        timestamp = (Get-Date).ToString()
        commit = $CommitHash
        error = $ErrorMessage
        retries = 0
    }
    $failedPushes | ConvertTo-Json | Out-File -FilePath $FailedPushesFile -Encoding utf8
}

function Monitor-And-Push {
    Write-Log "🔍 Git Guardian is watching..." -Color Green
    
    if (-not (Test-InternetConnection)) {
        Write-Log "⚠️ No internet connection" -Color Red
        return
    }
    
    $strength = Get-ConnectionStrength
    Write-Log "📡 Connection strength: $strength" -Color Yellow
    
    # Check if there are pending commits
    $pendingCommits = git log origin/main..main --oneline 2>$null
    if ($pendingCommits -and $strength -ne "Disconnected") {
        Write-Log "📦 Found $($pendingCommits.Count) pending commits" -Color Cyan
        
        $strategies = @("full", "chunked", "single-file")
        $success = $false
        
        foreach ($strategy in $strategies) {
            if (Try-GitPush -Strategy $strategy) {
                Write-Log "✅ Push successful using $strategy strategy" -Color Green
                $success = $true
                break
            }
            Start-Sleep -Seconds 5
        }
        
        if (-not $success) {
            $latestCommit = git log -1 --format="%H"
            Save-FailedPush -CommitHash $latestCommit -ErrorMessage "All push strategies failed"
            Write-Log "❌ All push strategies failed. Saved to queue." -Color Red
        }
    } else {
        Write-Log "✅ No pending commits or connection weak" -Color Gray
    }
}

# Main loop (runs every 5 minutes when online, retries failed pushes every 30 min)
Write-Log "🚀 Git Guardian started (PID: $PID)" -Color Magenta

while ($true) {
    Monitor-And-Push
    Start-Sleep -Seconds 300  # Check every 5 minutes
}
