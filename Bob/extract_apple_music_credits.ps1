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

function Get-TrackCredits {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    Write-Host "Processing: $Url" -ForegroundColor Cyan

    # curl.exeを使用し、バイナリモードで取得してUTF-8としてデコード
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        # バイナリモードでファイルに保存
        & curl.exe -L -A $userAgent -s -o $tempFile $Url
        # ファイルからUTF-8として読み込み
        $html = [System.IO.File]::ReadAllText($tempFile, [System.Text.Encoding]::UTF8)
    } finally {
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }

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

    $trackNameMatch = [regex]::Match($json, '"name":"([^"]+)".{0,300}"songId":"', 'Singleline')
    $trackName = if ($trackNameMatch.Success) { $trackNameMatch.Groups[1].Value } else { $Url }

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
        $producerMatches = [regex]::Matches(
            $productionSection.Groups[1].Value,
            '(?is)"name":"([^"]+)".{0,200}?"roleNames":\[(.*?)\]'
        )

        foreach ($producerMatch in $producerMatches) {
            $name = $producerMatch.Groups[1].Value
            $roles = $producerMatch.Groups[2].Value

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

$urls = Get-Content $creditFile |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -match '^https?://' }

$results = foreach ($url in $urls) {
    Get-TrackCredits -Url $url
}

$lines = @(
    "# Selected Tracks Credits",
    ""
)

foreach ($result in $results) {
    $lines += "### $($result.TrackName)"
    $lines += ""
    
    $composerList = if ($result.Composers) { [string]::Join(', ', $result.Composers) } else { "N/A" }
    $producerList = if ($result.Producers) { [string]::Join(', ', $result.Producers) } else { "**[MANUAL INPUT REQUIRED]**" }
    $performerList = if ($result.Performers) { [string]::Join(', ', $result.Performers) } else { "N/A" }
    
    $lines += "- **Composer**: $composerList"
    $lines += "- **Producer**: $producerList"
    $lines += "- **Performer**: $performerList"
    $lines += ""
}

# BOM付きUTF-8で保存
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllLines($outputFile, $lines, $utf8WithBom)

Write-Host "`nCreated: $outputFile" -ForegroundColor Green

# Made with Bob
