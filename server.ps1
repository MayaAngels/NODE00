# server.ps1 - Simple web server for Render
$port = $env:PORT
if (-not $port) { $port = 10000 }

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:$port/")
$listener.Start()
Write-Host "Ω-Server running on port $port"

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    
    $path = $request.Url.AbsolutePath
    if ($path -eq "/" -or $path -eq "/dashboard") { $path = "/dashboard.html" }
    if ($path -eq "/api/dashboard") {
        # Call our api.ps1
        $json = & "C:\Users\Maya\NewDigitalShop\NODE00\api.ps1"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
        $response.ContentType = "application/json"
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    } else {
        $filePath = "C:\Users\Maya\NewDigitalShop\NODE00$path"
        if (Test-Path $filePath) {
            $buffer = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = "text/html"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        } else {
            $response.StatusCode = 404
        }
    }
    $response.Close()
}
