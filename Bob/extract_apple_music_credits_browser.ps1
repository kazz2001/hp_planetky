$ErrorActionPreference = "Stop"

# UTF-8エンコーディングを設定
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$creditFile = Join-Path $PSScriptRoot "credit.MD"
$outputDir = Join-Path $PSScriptRoot "output"
$outputFile = Join-Path $outputDir "selected_tracks_credits.md"

if (-not (Test-Path $creditFile)) {
    throw "Input file not found: $creditFile"
}

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Puppeteerを使用してブラウザでページを開き、HTMLを取得する関数
function Get-TrackCreditsWithBrowser {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    Write-Host "Processing: $Url" -ForegroundColor Cyan

    # 一時ファイルにHTMLを保存
    $tempHtmlFile = [System.IO.Path]::GetTempFileName() + ".html"
    
    # Puppeteerスクリプトを作成
    $puppeteerScript = @"
const puppeteer = require('puppeteer');
const fs = require('fs');

(async () => {
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
    
    await page.goto('$Url', { waitUntil: 'networkidle0', timeout: 30000 });
    
    // ページが完全に読み込まれるまで待機
    await page.waitForTimeout(3000);
    
    const html = await page.content();
    fs.writeFileSync('$tempHtmlFile', html, 'utf8');
    
    await browser.close();
})();
"@

    $tempScriptFile = [System.IO.Path]::GetTempFileName() + ".js"
    Set-Content -Path $tempScriptFile -Value $puppeteerScript -Encoding UTF8

    try {
        # Node.jsでPuppeteerスクリプトを実行
        & node $tempScriptFile
        
        if (-not (Test-Path $tempHtmlFile)) {
            throw "Failed to retrieve HTML for: $Url"
        }

        $html = Get-Content -Path $tempHtmlFile -Raw -Encoding UTF8
        
    } finally {
        # 一時ファイルを削除
        if (Test-Path $tempScriptFile) { Remove-Item $tempScriptFile -Force }
        if (Test-Path $tempHtmlFile) { Remove-Item $tempHtmlFile -Force }
    }

    # JSONデータを抽出
    $match = [regex]::Match(
        $html,
        '(?is)<script type="application/json" id="serialized-server-data">(.*?)</script>'
    )

    if (-not $match.Success) {
        Write-Warning "serialized-server-data not found for URL: $Url"
        return [PSCustomObject]@{
            TrackName  = $Url
            Composers  = @()
            Producers  = @()
            Performers = @()
        }
    }

    $json = $match.Groups[1].Value

    # トラック名を抽出
    $trackNameMatch = [regex]::Match($json, '"name":"([^"]+)".{0,300}"songId":"', 'Singleline')
    $trackName = if ($trackNameMatch.Success) { $trackNameMatch.Groups[1].Value } else { $Url }

    # 各セクションを抽出
    $performerSection = [regex]::Match(
        $json,
        '(?is)"id":"performer".*?"items":\[(.*?)\],"presentation"'
    )
    $composerSection = [regex]::Match(
        $json,
        '(?is)"id":"composer-and-lyrics".*?"items":\[(.*?)\],"presentation"'
    )
    $productionSection = [regex]::Match(
        $json,
        '(?is)"id":"production-and-engineering".*?"items":\[(.*?)\],"presentation"'
    )

    $performers = @()
    $composers = @()
    $producers = @()

    if ($performerSection.Success) {
        $performers = [regex]::Matches($performerSection.Groups[1].Value, '"name":"([^"]+)"') |
            ForEach-Object { $_.Groups[1].Value } |
            Select-Object -Unique
    }

    if ($composerSection.Success) {
        $composers = [regex]::Matches($composerSection.Groups[1].Value, '"name":"([^"]+)"') |
            ForEach-Object { $_.Groups[1].Value } |
            Select-Object -Unique
    }

    if ($productionSection.Success) {
        # すべてのnameとroleNamesを抽出
        $producerMatches = [regex]::Matches(
            $productionSection.Groups[1].Value,
            '(?is)"name":"([^"]+)".{0,300}?"roleNames":\[(.*?)\]'
        )

        foreach ($producerMatch in $producerMatches) {
            $name = $producerMatch.Groups[1].Value
            $roles = $producerMatch.Groups[2].Value

            # "Producer"または"プロデューサー"を含む場合
            if ($roles -match 'Producer|プロデューサー|プロ') {
                $producers += $name
            }
        }

        $producers = $producers | Select-Object -Unique
    }

    [PSCustomObject]@{
        TrackName  = $trackName
        Composers  = $composers
        Producers  = $producers
        Performers = $performers
    }
}

# URLリストを取得
$urls = Get-Content $creditFile |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -match '^https?://' }

Write-Host "`nProcessing $($urls.Count) URLs..." -ForegroundColor Green

$results = foreach ($url in $urls) {
    Get-TrackCreditsWithBrowser -Url $url
}

# 結果をMarkdown形式で出力
$lines = @(
    "# Selected Tracks Credits",
    ""
)

foreach ($result in $results) {
    $lines += "- $($result.TrackName)"
    
    $composerList = if ($result.Composers) { [string]::Join(', ', $result.Composers) } else { "N/A" }
    $producerList = if ($result.Producers) { [string]::Join(', ', $result.Producers) } else { "N/A" }
    $performerList = if ($result.Performers) { [string]::Join(', ', $result.Performers) } else { "N/A" }
    
    $lines += "  - Composer: $composerList"
    $lines += "  - Producer: $producerList"
    $lines += "  - Performer: $performerList"
    $lines += ""
}

# BOM付きUTF-8で保存
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllLines($outputFile, $lines, $utf8WithBom)

Write-Host "`nCreated: $outputFile" -ForegroundColor Green

# Made with Bob