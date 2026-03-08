#!/usr/bin/env node
/**
 * AllMusic Track Listing Scraper
 * AllMusicのアルバムページからトラックリストとComposer情報を取得し、HTMLテーブルを生成します。
 */

const https = require('https');
const fs = require('fs');

/**
 * PT00H02M34S形式から2:34形式に変換
 */
function convertDuration(duration) {
    // durationがundefinedまたはnullの場合は"Unknown"を返す
    if (!duration) {
        return "Unknown";
    }
    
    const match = duration.match(/PT00H(\d+)M(\d+)S/);
    if (match) {
        const minutes = parseInt(match[1]);
        const seconds = match[2];
        return `${minutes}:${seconds}`;
    }
    return duration;
}

/**
 * HTTPSリクエストを実行してHTMLを取得
 */
function fetchPage(url) {
    return new Promise((resolve, reject) => {
        const options = {
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        };

        https.get(url, options, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                resolve(data);
            });
        }).on('error', (err) => {
            reject(err);
        });
    });
}

/**
 * 各曲のページからComposerとPerformer情報を取得
 */
async function getTrackDetails(url) {
    try {
        const html = await fetchPage(url);
        
        // Composer情報を抽出
        let composer = "Unknown";
        const composerMatch = html.match(/<div class="composer">(.*?)<\/div>\s*<\/div>/s);
        if (composerMatch) {
            const composerSection = composerMatch[1];
            // 各作曲者の名前を抽出
            const composers = [...composerSection.matchAll(/<a[^>]*>([^<]+)<\/a>/g)]
                .map(match => match[1]);
            if (composers.length > 0) {
                composer = composers.join(' / ');
            }
        }
        
        // Performer情報を抽出
        let performer = "Unknown";
        let performers = [];
        
        // 方法1: performerクラスのdivから、次のクラス（composer, lyricist, producer等）が出現するまでの全テキストを取得
        const performerMatch = html.match(/<div class="performer">([\s\S]*?)(?=<div class="(?:composer|lyricist|producer|arranger|engineer|mixing|mastering)"|<\/section>|<section)/);
        if (performerMatch) {
            const performerSection = performerMatch[1];
            
            // 各パフォーマーの名前を抽出
            performers = [...performerSection.matchAll(/<a[^>]*>([^<]+)<\/a>/g)]
                .map(match => match[1].trim());
        }
        
        // 方法2: Performerラベルから次のラベルまでを取得
        if (performers.length === 0) {
            const performerSectionMatch = html.match(/Performer[s]?<\/span>([\s\S]*?)(?=<span[^>]*>(?:Composer|Lyricist|Producer|Arranger|Engineer|Mixing|Mastering)|<\/section>)/);
            if (performerSectionMatch) {
                const performerSection = performerSectionMatch[1];
                performers = [...performerSection.matchAll(/<a[^>]*>([^<]+)<\/a>/g)]
                    .map(match => match[1].trim());
            }
        }
        
        // 方法3: より広範囲で検索（最大5000文字）
        if (performers.length === 0) {
            const performerSectionMatch = html.match(/Performer[s]?<\/span>([\s\S]{0,5000}?)(?=<div class="(?:composer|lyricist|producer)|<\/section>)/);
            if (performerSectionMatch) {
                const performerSection = performerSectionMatch[1];
                performers = [...performerSection.matchAll(/<a[^>]*>([^<]+)<\/a>/g)]
                    .map(match => match[1].trim());
            }
        }
        
        // 方法4: titleタグから抽出（フォールバック）
        if (performers.length === 0) {
            const titleMatch = html.match(/<title>([^<]+)<\/title>/);
            if (titleMatch) {
                const titleContent = titleMatch[1];
                // "曲名 - アーティスト名 | AllMusic" の形式から抽出
                const parts = titleContent.split('|')[0].trim();
                const artistPart = parts.split(' - ').slice(1).join(' - ').trim();
                
                if (artistPart) {
                    // カンマで分割
                    performers = artistPart.split(',').map(a => a.trim());
                }
            }
        }
        
        // Performerを "メインアーティスト feat: その他" の形式にフォーマット
        if (performers.length > 0) {
            if (performers.length === 1) {
                performer = performers[0];
            } else {
                // 最初のアーティストをメインに、残りをfeat:で結合
                const mainArtist = performers[0];
                const featArtists = performers.slice(1);
                performer = `${mainArtist} feat: ${featArtists.join(', ')}`;
            }
        }
        
        return { composer, performer };
    } catch (error) {
        console.error(`エラー (${url}):`, error.message);
        return { composer: "Unknown", performer: "Unknown" };
    }
}

/**
 * アルバムページのHTMLを取得
 */
async function fetchAlbumPage(albumUrl) {
    try {
        return await fetchPage(albumUrl);
    } catch (error) {
        console.error(`アルバムページの取得に失敗しました: ${error.message}`);
        process.exit(1);
    }
}

/**
 * HTMLからトラック情報を抽出
 */
function extractTracks(html) {
    const tracksMatch = html.match(/"tracks":\s*\[(.*?)\]/s);
    if (!tracksMatch) {
        console.error("トラック情報が見つかりませんでした");
        process.exit(1);
    }
    
    const tracksJson = '[' + tracksMatch[1] + ']';
    return JSON.parse(tracksJson);
}

/**
 * HTMLテーブルを生成
 */
function generateHtmlTable(trackData, albumTitle = "Album") {
    let htmlOutput = `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>${albumTitle} - Track Listing</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        .t3-p {
            border-collapse: collapse;
            width: 100%;
        }
        .t3-p td {
            border: 1px solid #ccc;
            padding: 8px;
        }
        .t3-p tr:first-child {
            background-color: #f0f0f0;
            font-weight: bold;
        }
        .header1 {
            background-color: #333;
            color: white;
            padding: 10px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <table>
        <tr>
            <td colspan="5" class="header1">Tracks</td>
        </tr>
        <tr>
            <td colspan="5">
                <table class="t3-p">
                    <tbody>
                        <tr>
                            <td>No.</td>
                            <td>Title</td>
                            <td>Composer</td>
                            <td>Performer</td>
                            <td>Time</td>
                        </tr>
`;
    
    // 各トラックを追加
    for (const track of trackData) {
        htmlOutput += `                        <tr>
                            <td align="right">${track.no}</td>
                            <td>${track.title}</td>
                            <td>${track.composer}</td>
                            <td>${track.performer}</td>
                            <td>${track.duration}</td>
                        </tr>
`;
    }
    
    htmlOutput += `                    </tbody>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>`;
    
    return htmlOutput;
}

/**
 * 待機関数
 */
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * メイン処理
 */
async function main() {
    // コマンドライン引数のチェック
    if (process.argv.length < 3) {
        console.log("使用方法: node allmusic_track_scraper.js <AllMusic Album URL> [output_file.html]");
        console.log("例: node allmusic_track_scraper.js https://www.allmusic.com/album/addison-mw0004526525");
        process.exit(1);
    }
    
    const albumUrl = process.argv[2];
    const path = require('path');
    const outputFile = process.argv[3]
        ? path.join('Bob', process.argv[3])
        : path.join('Bob', 'track_listing.html');
    
    console.log(`アルバムページを取得中: ${albumUrl}`);
    const html = await fetchAlbumPage(albumUrl);
    
    console.log("トラック情報を抽出中...");
    const tracks = extractTracks(html);
    
    // アルバムタイトルとアーティスト名を抽出
    const albumTitleMatch = html.match(/<title>([^<]+)<\/title>/);
    const albumTitle = albumTitleMatch ? albumTitleMatch[1].split('|')[0].trim() : "Album";
    
    console.log(`\n各曲のComposerとPerformer情報を取得中（全${tracks.length}曲）...`);
    const trackData = [];
    
    for (let i = 0; i < tracks.length; i++) {
        const track = tracks[i];
        const title = track.name.replace(/&/g, '&');
        const duration = convertDuration(track.duration);
        const url = track.url;
        
        console.log(`${i + 1}/${tracks.length}: ${title}`);
        const { composer, performer } = await getTrackDetails(url);
        console.log(`  → Performer: ${performer}`);
        
        trackData.push({
            no: i + 1,
            title: title,
            composer: composer,
            performer: performer,
            duration: duration
        });
        
        // レート制限を避けるため少し待機
        if (i < tracks.length - 1) {
            await sleep(1000);
        }
    }
    
    console.log("\nHTMLテーブルを生成中...");
    const htmlOutput = generateHtmlTable(trackData, albumTitle);
    
    // ファイルに保存
    fs.writeFileSync(outputFile, htmlOutput, 'utf-8');
    
    console.log(`\n✓ HTMLファイルを作成しました: ${outputFile}`);
    console.log(`\n=== トラックリスト（全${trackData.length}曲）===`);
    for (const track of trackData) {
        console.log(`${track.no.toString().padStart(2)}. ${track.title}`);
        console.log(`    Composer: ${track.composer}`);
        console.log(`    Duration: ${track.duration}`);
    }
}

// スクリプト実行
if (require.main === module) {
    main().catch(error => {
        console.error("エラーが発生しました:", error);
        process.exit(1);
    });
}

// Made with Bob