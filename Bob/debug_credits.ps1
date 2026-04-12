$ErrorActionPreference = "Stop"

# UTF-8エンコーディングを設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$url = "https://music.apple.com/jp/song/community/1812517700"

Write-Host "Fetching URL: $url" -ForegroundColor Cyan

# curl.exeでHTMLを取得（User-Agentを設定してUTF-8で取得）
$userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
$htmlBytes = & curl.exe -L -A $userAgent -s $url
# UTF-8として明示的にデコード
$html = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes($htmlBytes))

Write-Host "`n=== HTML Length: $($html.Length) ===" -ForegroundColor Yellow

# HTMLの最初の2000文字を表示
Write-Host "`n=== First 2000 characters of HTML ===" -ForegroundColor Cyan
Write-Host $html.Substring(0, [Math]::Min(2000, $html.Length))

$match = [regex]::Match(
    $html,
    '(?is)<script type="application/json" id="serialized-server-data">(.*?)</script>'
)

if (-not $match.Success) {
    Write-Host "`n=== Searching for alternative script tags ===" -ForegroundColor Yellow
    $scriptMatches = [regex]::Matches($html, '(?is)<script[^>]*>(.*?)</script>')
    Write-Host "Found $($scriptMatches.Count) script tags"
    
    for ($i = 0; $i -lt [Math]::Min(3, $scriptMatches.Count); $i++) {
        Write-Host "`n--- Script $($i + 1) (first 500 chars) ---" -ForegroundColor Green
        $scriptContent = $scriptMatches[$i].Value
        Write-Host $scriptContent.Substring(0, [Math]::Min(500, $scriptContent.Length))
    }
    
    throw "serialized-server-data not found"
}

$json = $match.Groups[1].Value

# Production sectionを抽出
$productionSection = [regex]::Match(
    $json,
    '(?is)"id":"production-and-engineering".*?"items":\[(.*?)\],"presentation"'
)

if ($productionSection.Success) {
    Write-Host "`n=== Production Section Found ===" -ForegroundColor Green
    $sectionData = $productionSection.Groups[1].Value
    
    # 最初の500文字を表示
    Write-Host "`nFirst 1000 characters of production section:" -ForegroundColor Yellow
    Write-Host $sectionData.Substring(0, [Math]::Min(1000, $sectionData.Length))
    
    # すべてのnameとroleNamesのペアを抽出
    Write-Host "`n=== All Names and Roles ===" -ForegroundColor Green
    $allMatches = [regex]::Matches(
        $sectionData,
        '(?is)"name":"([^"]+)".{0,300}?"roleNames":\[(.*?)\]'
    )
    
    foreach ($m in $allMatches) {
        Write-Host "`nName: $($m.Groups[1].Value)" -ForegroundColor Cyan
        Write-Host "Roles: $($m.Groups[2].Value)" -ForegroundColor Yellow
    }
} else {
    Write-Host "Production section NOT found" -ForegroundColor Red
}

# Made with Bob
