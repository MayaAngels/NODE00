# api-blog.ps1
$requestPath = $env:REQUEST_PATH

if ($requestPath -eq "/api/blog-posts") {
    $posts = @()
    $blogDir = "blog"
    $files = Get-ChildItem "$blogDir\*.html" | Where-Object { $_.Name -ne "index.html" -and $_.Name -ne "post-template.html" }
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw
        # Extrair título e excerpt (simplificado)
        $titleMatch = [regex]::Match($content, '<h1>(.*?)</h1>')
        $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $file.BaseName }
        $excerptMatch = [regex]::Match($content, '<meta name="description" content="(.*?)">')
        $excerpt = if ($excerptMatch.Success) { $excerptMatch.Groups[1].Value } else { "Leia mais sobre $title" }
        $posts += @{
            slug = $file.BaseName
            title = $title
            date = (Get-Date $file.CreationTime).ToString("dd/MM/yyyy")
            excerpt = $excerpt
        }
    }
    $posts | ConvertTo-Json
}
