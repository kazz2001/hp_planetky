<#
.SYNOPSIS
    Genius.comのアルバムページからトラック情報を取得し、planet.KY形式のHTMLファイルを生成します。
    Genius APIトークンを使用してCloudflare検知を回避し、完全なProducer/Writer情報を取得します。

.PARAMETER AlbumUrl
    Genius.comのアルバムページURL
    例: https://genius.com/albums/Jim-legxacy/Black-british-music-2025

.PARAMETER OutputFilePrefix
    出力HTMLファイル名のプレフィックス（省略可能）
    指定しない場合は、アーティスト名から自動生成されます
    例: "jimlegxacy" を指定すると "jimlegxacy1.htm" として出力されます

.PARAMETER GeniusToken
    Genius APIのClient Access Token（省略可能）
    指定しない場合は環境変数 GENIUS_ACCESS_TOKEN から自動取得します

.EXAMPLE
    .\genius_album_to_html.ps1 -AlbumUrl "https://genius.com/albums/Jim-legxacy/Black-british-music-2025"
    
.EXAMPLE
    .\genius_album_to_html.ps1 -AlbumUrl "https://genius.com/albums/Jim-legxacy/Black-british-music-2025" -OutputFilePrefix "jimlegxacy"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$AlbumUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFilePrefix = "",

    [Parameter(Mandatory=$false)]
    [string]$GeniusToken = ""
)

Add-Type -AssemblyName System.Web

# ---- トークン取得 ----
if (-not $GeniusToken) {
    $GeniusToken = [System.Environment]::GetEnvironmentVariable('GENIUS_ACCESS_TOKEN', 'User')
    if (-not $GeniusToken) {
        $GeniusToken = $env:GENIUS_ACCESS_TOKEN
    }
}

if (-not $GeniusToken) {
    Write-Error "Genius APIトークンが見つかりません。環境変数 GENIUS_ACCESS_TOKEN を設定するか、-GeniusToken パラメーターで渡してください。"
    exit 1
}

# ---- 設定 ----
$OutputDir = Join-Path $PSScriptRoot "output"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$ApiHeaders = @{
    "Authorization" = "Bearer $GeniusToken"
    "User-Agent"    = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)"
}

function HtmlEnc([string]$s) { return [System.Web.HttpUtility]::HtmlEncode($s) }
function HtmlDec([string]$s) { return [System.Web.HttpUtility]::HtmlDecode($s) }

# ---- URL解析 ----
$artistSlug = ""
$albumSlug  = ""
if ($AlbumUrl -match '/albums/([^/]+)/([^/]+)') {
    $artistSlug = $matches[1]
    $albumSlug  = $matches[2]
} else {
    Write-Error "無効なGeniusアルバムURLです: $AlbumUrl"
    exit 1
}

$artistQuery = $artistSlug -replace '-', ' '
$albumQuery  = $albumSlug  -replace '-', ' '

Write-Host "アルバム情報を Genius API から検索中: $artistQuery / $albumQuery" -ForegroundColor Cyan

# ---- 1. アルバム検索 ----
$targetAlbum = $null

# 方法A: アーティスト名 + アルバム名で検索
$searchUrl = "https://api.genius.com/search?q=" + [System.Web.HttpUtility]::UrlEncode("$artistQuery $albumQuery")
try {
    $searchRes = Invoke-RestMethod -Uri $searchUrl -Headers $ApiHeaders
    if ($searchRes.response.hits) {
        foreach ($hit in $searchRes.response.hits) {
            try {
                $sDetail = Invoke-RestMethod -Uri "https://api.genius.com/songs/$($hit.result.id)" -Headers $ApiHeaders
                $alb = $sDetail.response.song.album
                if ($alb -and ($alb.url -like "*$albumSlug*" -or $alb.name.ToLower() -eq $albumQuery.ToLower())) {
                    $targetAlbum = $alb
                    break
                }
            } catch {}
        }
    }
} catch {
    Write-Warning "検索APIの呼び出しでエラーが発生しました: $_"
}

# 方法B: 見つからない場合、アーティストの楽曲一覧からアルバムを探す
if (-not $targetAlbum) {
    Write-Host "アーティスト楽曲一覧からアルバムを検索中..." -ForegroundColor Cyan
    $artistSearchUrl = "https://api.genius.com/search?q=" + [System.Web.HttpUtility]::UrlEncode($artistQuery)
    $artistId = $null
    try {
        $artistSearchRes = Invoke-RestMethod -Uri $artistSearchUrl -Headers $ApiHeaders
        foreach ($h in $artistSearchRes.response.hits) {
            if ($h.result.primary_artist.slug -eq $artistSlug.ToLower() -or $h.result.primary_artist.name.ToLower() -eq $artistQuery.ToLower()) {
                $artistId = $h.result.primary_artist.id
                break
            }
        }
    } catch {}

    if ($artistId) {
        $page = 1
        while ($page -le 5 -and -not $targetAlbum) {
            try {
                $songsRes = Invoke-RestMethod -Uri "https://api.genius.com/artists/$artistId/songs?page=$page&per_page=50&sort=popularity" -Headers $ApiHeaders
                foreach ($s in $songsRes.response.songs) {
                    try {
                        $sDetail = Invoke-RestMethod -Uri "https://api.genius.com/songs/$($s.id)" -Headers $ApiHeaders
                        $alb = $sDetail.response.song.album
                        if ($alb -and ($alb.url -like "*$albumSlug*" -or $alb.name.ToLower() -eq $albumQuery.ToLower())) {
                            $targetAlbum = $alb
                            break
                        }
                    } catch {}
                }
            } catch { break }
            $page++
        }
    }
}

if (-not $targetAlbum) {
    Write-Error "Genius APIでアルバム情報を取得できませんでした: $AlbumUrl"
    exit 1
}

$albumId    = $targetAlbum.id
$albumName  = $targetAlbum.name
$artistName = if ($targetAlbum.artist.name) { $targetAlbum.artist.name } else { (Get-Culture).TextInfo.ToTitleCase($artistQuery.ToLower()) }

Write-Host "アーティスト: $artistName" -ForegroundColor Green
Write-Host "アルバム    : $albumName (ID: $albumId)" -ForegroundColor Green

# ---- 2. トラックリスト取得 ----
Write-Host "トラックリストを取得中..." -ForegroundColor Cyan
$tracksRes = Invoke-RestMethod -Uri "https://api.genius.com/albums/$albumId/tracks" -Headers $ApiHeaders
$rawTracks = $tracksRes.response.tracks
Write-Host "トラック数  : $($rawTracks.Count)" -ForegroundColor Green

# ---- 3. 各トラックの詳細情報取得 ----
$tracks = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($t in $rawTracks) {
    $trackNum = $t.number
    $songId   = $t.song.id
    $title    = $t.song.title
    Write-Host "  [$trackNum/$($rawTracks.Count)] $title (ID: $songId)" -ForegroundColor Yellow

    $writers   = [System.Collections.Generic.List[string]]::new()
    $producers = [System.Collections.Generic.List[string]]::new()
    $featured  = [System.Collections.Generic.List[string]]::new()

    try {
        $songDetail = Invoke-RestMethod -Uri "https://api.genius.com/songs/$songId" -Headers $ApiHeaders
        $s = $songDetail.response.song

        if ($s.writer_artists) {
            foreach ($w in $s.writer_artists) {
                if ($w.name) { $writers.Add($w.name.Trim()) }
            }
        }
        if ($s.producer_artists) {
            foreach ($p in $s.producer_artists) {
                if ($p.name) { $producers.Add($p.name.Trim()) }
            }
        }
        if ($s.featured_artists) {
            foreach ($f in $s.featured_artists) {
                if ($f.name) { $featured.Add($f.name.Trim()) }
            }
        }
    } catch {
        Write-Warning "曲の詳細情報取得に失敗しました (ID: $songId): $_"
    }

    # Performer 文字列構築
    $performer = $artistName
    if ($featured.Count -gt 0) {
        $performer = "$artistName feat. $($featured -join ' & ')"
    }

    $uniqueWriters   = ($writers   | Select-Object -Unique)
    $uniqueProducers = ($producers | Select-Object -Unique)
    $uniqueFeatured  = ($featured  | Select-Object -Unique)

    $tracks.Add([PSCustomObject]@{
        Number    = $trackNum
        Title     = $title
        Composers = $uniqueWriters   -join " / "
        Performer = $performer
        Time      = ""
        Producers = $uniqueProducers -join ", "
        Featured  = $uniqueFeatured  -join ", "
    })

    Start-Sleep -Milliseconds 150
}

# ---- Producers セクション集約 ----
$producerGroups = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[int]]]::new()
for ($i = 0; $i -lt $tracks.Count; $i++) {
    $prod = $tracks[$i].Producers
    if ($prod) {
        if (-not $producerGroups.ContainsKey($prod)) {
            $producerGroups[$prod] = [System.Collections.Generic.List[int]]::new()
        }
        $producerGroups[$prod].Add($i + 1)
    }
}

$producersLines = [System.Collections.Generic.List[string]]::new()
foreach ($kv in $producerGroups.GetEnumerator()) {
    $nums = $kv.Value -join ","
    $producersLines.Add("$($kv.Key)($nums)")
}
$producersHtml = if ($producersLines.Count -gt 0) { ($producersLines -join "<br>`n") + "<br>" } else { "&nbsp;" }

# ---- Guests セクション集約 ----
$guestList = [System.Collections.Generic.List[string]]::new()
for ($i = 0; $i -lt $tracks.Count; $i++) {
    $feat = $tracks[$i].Featured
    if ($feat) { $guestList.Add("$feat($($i + 1))") }
}
$guestsHtml = if ($guestList.Count -gt 0) { $guestList -join ", " } else { "&nbsp;" }

# ---- Tracks テーブル HTML 生成 ----
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('            <table class="t3-p">')
[void]$sb.AppendLine('              <tbody>')
[void]$sb.AppendLine('                <tr>')
[void]$sb.AppendLine('                  <td>No.</td>')
[void]$sb.AppendLine('                  <td>Title</td>')
[void]$sb.AppendLine('                  <td>Composer</td>')
[void]$sb.AppendLine('                  <td>Performer</td>')
[void]$sb.AppendLine('                  <td>Time</td>')
[void]$sb.AppendLine('                </tr>')

foreach ($track in $tracks) {
    [void]$sb.AppendLine('                <tr>')
    [void]$sb.AppendLine("                  <td align=""right"">$($track.Number)</td>")
    [void]$sb.AppendLine("                  <td>$(HtmlEnc($track.Title))</td>")
    [void]$sb.AppendLine("                  <td>$(HtmlEnc($track.Composers))</td>")
    [void]$sb.AppendLine("                  <td>$(HtmlEnc($track.Performer))</td>")
    [void]$sb.AppendLine('                  <td></td>')
    [void]$sb.AppendLine('                </tr>')
}

[void]$sb.AppendLine('              </tbody>')
[void]$sb.Append('            </table>')
$tracksTableHtml = $sb.ToString()

# ---- ファイル名生成 ----
$safeArtist = ($artistName -replace '[^a-zA-Z0-9]', '').ToLower()
if ($OutputFilePrefix) {
    $outputFileName = "${OutputFilePrefix}.htm"
} else {
    $outputFileName = "${safeArtist}1_tracks.htm"
}
$outputPath = Join-Path $OutputDir $outputFileName

# ---- HTML テンプレート生成 ----
$nl = "`n"
$htmlParts = [System.Collections.Generic.List[string]]::new()
$htmlParts.Add('<!DOCTYPE HTML >')
$htmlParts.Add('<html><!-- #BeginTemplate "/Templates/CDREVIEWU.dwt" --><!-- DW6 -->')
$htmlParts.Add('<head><!-- Global site tag (gtag.js) - Google Analytics --><script async src="https://www.googletagmanager.com/gtag/js?id=UA-54911-2"></script> <script>')
$htmlParts.Add('  window.dataLayer = window.dataLayer || [];')
$htmlParts.Add('  function gtag(){dataLayer.push(arguments);}')
$htmlParts.Add('  gtag(''js'', new Date());')
$htmlParts.Add('')
$htmlParts.Add('  gtag(''config'', ''UA-54911-2'');')
$htmlParts.Add('</script>')
$htmlParts.Add('<meta name="viewport" content="width=device-width">')
$htmlParts.Add('<!-- #BeginEditable "doctitle" -->')
$htmlParts.Add('<meta name="GENERATOR" content="JustSystems Homepage Builder Version 17.0.15.0 for Windows">')
$htmlParts.Add("<meta name=""KEYWORD"" content=""$(HtmlEnc($artistName)), $(HtmlEnc($albumName))"">" )
$htmlParts.Add("<meta name=""description"" content=""CD review of $(HtmlEnc($artistName)) / $(HtmlEnc($albumName))"">" )
$htmlParts.Add("<meta name=""ABSTRACT"" content=""$(HtmlEnc($artistName)) / $(HtmlEnc($albumName))"">" )
$htmlParts.Add('<meta http-equiv="Content-Style-Type" content="text/css">')
$htmlParts.Add('<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">')
$htmlParts.Add("<title>$(HtmlEnc($artistName)) / $(HtmlEnc($albumName)) -CD Review-</title>")
$htmlParts.Add('<!-- #EndEditable -->')
$htmlParts.Add('<style>')
$htmlParts.Add('<!--')
$htmlParts.Add('')
$htmlParts.Add('-->')
$htmlParts.Add('</style>')
$htmlParts.Add('<script language="JavaScript">')
$htmlParts.Add('<!--')
$htmlParts.Add('function fc(w){')
$htmlParts.Add('  if(w == "")return;')
$htmlParts.Add('  document.menu0.url.selectedIndex = 0;')
$htmlParts.Add('  location.href=w;')
$htmlParts.Add('}')
$htmlParts.Add('')
$htmlParts.Add('function MM_jumpMenu(targ,selObj,restore){ //v3.0')
$htmlParts.Add('  eval(targ+".location=''"+selObj.options[selObj.selectedIndex].value+"''");')
$htmlParts.Add('  if (restore) selObj.selectedIndex=0;')
$htmlParts.Add('}')
$htmlParts.Add('//-->')
$htmlParts.Add('</script>')
$htmlParts.Add('<link rel="stylesheet" href="css/bm1.css" type="text/css">')
$htmlParts.Add('<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">')
$htmlParts.Add('</head>')
$htmlParts.Add('<body>')
$htmlParts.Add('<table class="t1">')
$htmlParts.Add('  <tbody>')
$htmlParts.Add('    <tr class="tr-left">')
$htmlParts.Add("      <td class=""td-g-black-180-mid"" rowspan=""5""><!-- #BeginEditable ""A"" --><img src=""gif/${safeArtist}1L.jpg"" width=""140"" height=""140"" border=""0""><br>")
$htmlParts.Add('      <font color="#FFFFFF" size="-1">(label : )</font><br>')
$htmlParts.Add('      <!-- #EndEditable --></td>')
$htmlParts.Add('      <td class="td-black" colspan="3"><a href="index.html"><img src="lo2.gif" class="header-img"></a></td>')
$htmlParts.Add('    </tr>')
$htmlParts.Add('    <tr>')
$htmlParts.Add('      <td rowspan="4" width="60">&nbsp;</td>')
$htmlParts.Add('      <td colspan="2" height="3">　</td>')
$htmlParts.Add('    </tr>')
$htmlParts.Add('    <tr>')
$htmlParts.Add('      <td class="td-left" colspan="2"><a href="http://ck.jp.ap.valuecommerce.com/servlet/referral?sid=2249009&pid=887194706" rel="nofollow"><img src="http://ad.jp.ap.valuecommerce.com/servlet/gifbanner?sid=2249009&pid=887194706" border="0"></a> </td>')
$htmlParts.Add('    </tr>')
$htmlParts.Add('    <tr>')
$htmlParts.Add('      <td colspan="2" class="td-left"><!-- #BeginLibraryItem "/Library/adv3.lbi" --><script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js">')
$htmlParts.Add('      </script> <ins class="adsbygoogle" style="display:block" data-ad-format="fluid" data-ad-layout-key="-fb+5w+4e-db+86" data-ad-client="ca-pub-4043025554204603" data-ad-slot="3858979378"></ins><script>')
$htmlParts.Add('        (adsbygoogle = window.adsbygoogle || []).push({});')
$htmlParts.Add('      </script><!-- #EndLibraryItem --></td>')
$htmlParts.Add('    </tr>')
$htmlParts.Add('    <tr>')
$htmlParts.Add('      <td width="420" class="td-left"><!-- #BeginLibraryItem "/Library/BMContent1.lbi" -->')
$htmlParts.Add('      <form name="form1"><select name="AnotherYear" onchange="MM_jumpMenu(''parent'',this,1)">')
$htmlParts.Add('        <option selected>Album Review : Select Year </option>')
foreach ($yr in @(2025,2024,2023,2022,2021,2020,2019,2018,2017,2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998)) {
    $val = if ($yr -eq 2025) { "cd.htm" } else { "cd$yr.htm" }
    $htmlParts.Add("        <option value=""$val"">$yr</option>")
}
$htmlParts.Add('      </select></form>')
$htmlParts.Add('      <form name="form1"><select name="AnotherYear" onchange="MM_jumpMenu(''parent'',this,1)">')
$htmlParts.Add('        <option selected>Best 50 : Select Year </option>')
foreach ($yr in @(2025,2024,2023,2022,2021,2020,2019,2018,2017,2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998)) {
    $htmlParts.Add("        <option value=""best$yr.htm"">$yr</option>")
}
$htmlParts.Add('      </select></form>')
$htmlParts.Add('      <!-- #EndLibraryItem --></td>')
$htmlParts.Add('      <td width="60" class="td-left"><!-- #BeginLibraryItem "/Library/BMCOntent2.lbi" --><!-- #EndLibraryItem --></td>')
$htmlParts.Add('    </tr>')
$htmlParts.Add('    <tr>')
$htmlParts.Add('      <td class="td-g-green">')
$htmlParts.Add('      <p class="header1-nobg">Site Contents</p>')
$htmlParts.Add('      </td>')
$htmlParts.Add('      <td class="td-gray"></td>')
$htmlParts.Add("      <td class=""section1"">CD Review :<!-- #BeginEditable ""B"" --> $(HtmlEnc($artistName)) / $(HtmlEnc($albumName))<!-- #EndEditable --></td>")
$htmlParts.Add('      <td class="section1">')
$htmlParts.Add('      <div class="td-m"><script language="JavaScript">')
$htmlParts.Add('          var imgFile')
$htmlParts.Add('          var imgFile2')
$htmlParts.Add('          imgFile = window.location.href.split(''/''). pop().split(''.'').shift()+"M.jpg";')
$htmlParts.Add('          imgFile2 = "<img src=gif/"+imgFile+" width=75>"')
$htmlParts.Add('          document.write(imgFile2);')
$htmlParts.Add('        </script> </div>')
$htmlParts.Add('      </td>')
$htmlParts.Add('    </tr>')
$htmlParts.Add('    <tr>')
$htmlParts.Add('      <td class="td-g-centertop-black"><!-- #BeginLibraryItem "/Library/BMMenu2.lbi" -->')
$htmlParts.Add('      <table>')
$htmlParts.Add('        <tbody>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td class="td-g-black">')
$htmlParts.Add('            <p class="p-white"><br>')
$htmlParts.Add('            Black Music Album Best 50<br>')
foreach ($yr in @(2025,2024,2023,2022,2021,2020,2019,2018,2017,2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998)) {
    $htmlParts.Add("            <a href=""best$yr.htm"" class=""size3"">$yr</a><br>")
}
$htmlParts.Add('            <br>')
$htmlParts.Add('            Album Review<br>')
foreach ($yr in @(2025,2024,2023,2022,2021,2020,2019,2018,2017,2016,2015,2014,2013,2012,2011,2010,2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,1999,1998)) {
    $val = if ($yr -eq 2025) { "cd.htm" } else { "cd$yr.htm" }
    $htmlParts.Add("            <a href=""$val"" class=""size3"">$yr</a><br>")
}
$htmlParts.Add('            <br>')
$htmlParts.Add('            <a href="reggaejazz.html" class="size2">Reggae & Jazz</a> <br>')
$htmlParts.Add('            <br>')
$htmlParts.Add('            <a href="liveshot.html" class="size2">Live Shot</a><br>')
$htmlParts.Add('            <br>')
$htmlParts.Add('            <a href="mag.htm" class="size2">Hip-Hop Magazine Review</a> <br>')
$htmlParts.Add('            <br>')
$htmlParts.Add('            <a href="http://planetky.com" class="size2">planet.KY home </a><br>')
$htmlParts.Add('            <br>')
$htmlParts.Add('            <br>')
$htmlParts.Add('            </p>')
$htmlParts.Add('            <p class="size2"><script language="JavaScript">')
$htmlParts.Add('      document.write(''Last updated at '', document.lastModified);')
$htmlParts.Add('      </script> </p>')
$htmlParts.Add('            <br>')
$htmlParts.Add('            <br>')
$htmlParts.Add('            </td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('        </tbody>')
$htmlParts.Add('      </table>')
$htmlParts.Add('      <!-- #EndLibraryItem --><!-- #BeginEditable "EditRegion1" --><!-- #EndEditable --></td>')
$htmlParts.Add('      <td>　</td>')
$htmlParts.Add('      <td colspan="2" class="td-left480"><!-- #BeginEditable "X" --><br>')
$htmlParts.Add('      <!-- #EndEditable -->')
$htmlParts.Add('      <table class="t2">')
$htmlParts.Add('        <col span="3">')
$htmlParts.Add('        <tbody>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="3" class="header1">Score Card</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr class="size1">')
$htmlParts.Add('            <td class="td-left">ラップ(rap oriented)</td>')
$htmlParts.Add('            <td class="td-center170"><!-- #BeginEditable "C" --><img src="1.gif" width="170" height="30" border="0"><!-- #EndEditable --></td>')
$htmlParts.Add('            <td class="td-right">歌(song oriented)</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr class="size1">')
$htmlParts.Add('            <td class="td-gray-left">アーバン(urban)</td>')
$htmlParts.Add('            <td class="td-center170-gray"><!-- #BeginEditable "D" --><img src="2.gif" width="170" height="30" border="0"><!-- #EndEditable --></td>')
$htmlParts.Add('            <td class="td-gray-right">アーシー(earthy)</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr class="size1">')
$htmlParts.Add('            <td class="td-left">聴きやすい(familiar)</td>')
$htmlParts.Add('            <td class="td-center170"><!-- #BeginEditable "E" --><img src="3.gif" width="170" height="30" border="0"><!-- #EndEditable --></td>')
$htmlParts.Add('            <td class="td-right">リスナーを選ぶ(serious)</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr class="size1">')
$htmlParts.Add('            <td class="td-gray-left">評点(rating)</td>')
$htmlParts.Add('            <td class="td-center170-gray"><!-- #BeginEditable "F" -->&nbsp;<!-- #EndEditable --></td>')
$htmlParts.Add('            <td class="td-gray-right">（5点満点 fullmark :5）</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr class="size1">')
$htmlParts.Add('            <td colspan="3"><!-- #BeginEditable "Y" -->&nbsp;<!-- #EndEditable --> </td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('        </tbody>')
$htmlParts.Add('      </table>')
$htmlParts.Add('      <table class="t3">')
$htmlParts.Add('        <col span="5">')
$htmlParts.Add('        <tbody>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="5" class="header1">Tracks <!-- #BeginEditable "G" --><!-- #EndEditable --></td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="5"><!-- #BeginEditable "H" -->')
$htmlParts.Add($tracksTableHtml)
$htmlParts.Add('            <!-- #EndEditable --></td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="5" class="header1">Producers</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add("            <td colspan=""5"" class=""size""><!-- #BeginEditable ""I"" -->$producersHtml<!-- #EndEditable --></td>")
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="5" class="header1">Guests</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add("            <td colspan=""5"" class=""size""><!-- #BeginEditable ""J"" -->$guestsHtml<!-- #EndEditable --></td>")
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="5" class="header1">Links</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add("            <td colspan=""5""><!-- #BeginEditable ""K"" --><a href=""$AlbumUrl"" target=""_blank"">Genius - $(HtmlEnc($albumName))</a><!-- #EndEditable --></td>")
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="5" class="header1">Other Reviews</td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="5"><!-- #BeginEditable "L" -->&nbsp;<!-- #EndEditable --></td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('          <tr>')
$htmlParts.Add('            <td colspan="5"><iframe src="https://rcm-fe.amazon-adsystem.com/e/cm?o=9&p=13&l=ur1&category=music&f=ifr&linkID=5d11b81ed2d7222a6622d08e1f7d21bf&t=planetkycom-22&tracking_id=planetkycom-22" width="468" height="60" scrolling="no" border="0" marginwidth="0" style="border:none;" frameborder="0"></iframe> </td>')
$htmlParts.Add('          </tr>')
$htmlParts.Add('        </tbody>')
$htmlParts.Add('      </table>')
$htmlParts.Add('      </td>')
$htmlParts.Add('    </tr>')
$htmlParts.Add('    <tr>')
$htmlParts.Add('      <td class="td-g-black"><br>')
$htmlParts.Add('      </td>')
$htmlParts.Add('      <td class="td-white">　</td>')
$htmlParts.Add('      <td class="td-gray" colspan="2">')
$htmlParts.Add('      <p><font size="-1" face="Times New Roman,Times,Times NewRoman">Copyright &copy; 1998-2026 planet.KY. All rights reserved.</font></p>')
$htmlParts.Add('      </td>')
$htmlParts.Add('    </tr>')
$htmlParts.Add('  </tbody>')
$htmlParts.Add('</table>')
$htmlParts.Add('</body>')
$htmlParts.Add('<!-- #EndTemplate --></html>')

$htmlContent = $htmlParts -join $nl

# ---- ファイル出力 ----
[System.IO.File]::WriteAllText($outputPath, $htmlContent, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "=== 完了 ===" -ForegroundColor Green
Write-Host "出力ファイル: $outputPath" -ForegroundColor Green
Write-Host "アーティスト: $artistName"  -ForegroundColor Green
Write-Host "アルバム    : $albumName"   -ForegroundColor Green
Write-Host "トラック数  : $($tracks.Count)" -ForegroundColor Green

Write-Host ""
Write-Host "--- Tracks ---" -ForegroundColor Cyan
foreach ($track in $tracks) {
    Write-Host "  $($track.Number). $($track.Title)" -ForegroundColor White
    if ($track.Composers) { Write-Host "     Composers: $($track.Composers)" -ForegroundColor Gray }
    if ($track.Producers) { Write-Host "     Producers: $($track.Producers)" -ForegroundColor Gray }
    if ($track.Featured)  { Write-Host "     Featured : $($track.Featured)"  -ForegroundColor Gray }
}
