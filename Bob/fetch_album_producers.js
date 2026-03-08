const https = require('https');
const fs = require('fs');

// シンプルなHTTP GETリクエスト関数
function fetchHTML(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

// HTMLから曲のタイトルとURLを抽出（汎用版）
function extractTracks(html, artistSlug) {
  const tracks = [];
  // アーティストスラッグを使用した柔軟な正規表現
  const trackRegex = new RegExp(`<a[^>]*href="(https:\\/\\/genius\\.com\\/${artistSlug}-[^"]*-lyrics)"[^>]*>([\\s\\S]*?)<\\/a>`, 'gi');
  let match;
  let trackNumber = 1;
  
  while ((match = trackRegex.exec(html)) !== null) {
    const url = match[1];
    // HTMLタグを除去してタイトルを取得
    const titleWithTags = match[2];
    let title = titleWithTags.replace(/<[^>]*>/g, '').trim();
    // "Lyrics"という文字列を除去
    title = title.replace(/\s*Lyrics\s*$/i, '').trim();
    
    // 重複を避ける
    if (title && !tracks.find(t => t.url === url)) {
      tracks.push({ number: trackNumber++, title, url });
    }
  }
  
  return tracks;
}

// HTMLからプロデューサー情報を抽出
function extractProducers(html) {
  // Producersセクションを探す
  const producerMatch = html.match(/Producers?<\/span>[\s\S]*?<div[^>]*>([\s\S]*?)<\/div>/i);
  
  if (!producerMatch) {
    return 'プロデューサー情報なし';
  }
  
  // リンクからプロデューサー名を抽出
  const producerSection = producerMatch[1];
  const nameRegex = /<a[^>]*>([^<]+)<\/a>/g;
  const producers = [];
  let match;
  
  while ((match = nameRegex.exec(producerSection)) !== null) {
    const name = match[1].trim();
    if (name && !producers.includes(name)) {
      producers.push(name);
    }
  }
  
  return producers.length > 0 ? producers.join(' & ') : 'プロデューサー情報なし';
}

// URLからアーティスト名とアルバム名を抽出
function parseGeniusUrl(url) {
  // https://genius.com/albums/Olivia-dean/The-art-of-loving
  const match = url.match(/genius\.com\/albums\/([^\/]+)\/([^\/\?#]+)/i);
  
  if (!match) {
    throw new Error('無効なGenius URLです。形式: https://genius.com/albums/Artist-name/Album-name');
  }
  
  return {
    artistSlug: match[1],
    albumSlug: match[2],
    artistName: match[1].replace(/-/g, ' '),
    albumName: match[2].replace(/-/g, ' ')
  };
}

async function fetchAlbumProducers(albumUrl) {
  console.log(`アクセス中: ${albumUrl}\n`);
  
  // URLからアーティストとアルバム情報を抽出
  const { artistSlug, albumSlug, artistName, albumName } = parseGeniusUrl(albumUrl);
  
  // アルバムページを取得
  const albumHTML = await fetchHTML(albumUrl);
  const tracks = extractTracks(albumHTML, artistSlug);
  
  console.log(`${tracks.length}曲見つかりました\n`);
  
  // 各曲のプロデューサー情報を取得
  const results = [];
  for (const track of tracks) {
    console.log(`取得中: ${track.number}. ${track.title}`);
    
    try {
      const trackHTML = await fetchHTML(track.url);
      const producer = extractProducers(trackHTML);
      
      results.push({
        number: track.number,
        title: track.title,
        producer: producer
      });
      
      // レート制限を避けるため少し待機
      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (error) {
      console.error(`  エラー: ${error.message}`);
      results.push({
        number: track.number,
        title: track.title,
        producer: 'エラー: 取得失敗'
      });
    }
  }
  
  return { results, artistName, albumName };
}

// プロデューサーごとに担当曲番号を集計
function aggregateProducersByTrack(results) {
  const producerMap = new Map();
  
  results.forEach(track => {
    const producer = track.producer;
    
    // エラーや情報なしの場合はスキップ
    if (producer.includes('エラー') || producer.includes('情報なし')) {
      return;
    }
    
    if (!producerMap.has(producer)) {
      producerMap.set(producer, []);
    }
    producerMap.get(producer).push(track.number);
  });
  
  // 最初の曲番号でソート
  const sortedProducers = Array.from(producerMap.entries())
    .sort((a, b) => a[1][0] - b[1][0]);
  
  return sortedProducers;
}

async function main() {
  // コマンドライン引数を取得
  const args = process.argv.slice(2);
  
  if (args.length < 1) {
    console.error('使い方: node fetch_album_producers.js <Genius アルバムURL>');
    console.error('例: node fetch_album_producers.js https://genius.com/albums/Olivia-dean/The-art-of-loving');
    console.error('');
    console.error('旧形式（非推奨）: node fetch_album_producers.js <アーティスト名> <アルバム名>');
    console.error('例: node fetch_album_producers.js Addison-rae Addison');
    process.exit(1);
  }
  
  let albumUrl;
  let artistName;
  let albumName;
  
  // URLが指定されたか、旧形式（アーティスト名 アルバム名）かを判定
  if (args[0].startsWith('http')) {
    // URL形式
    albumUrl = args[0];
  } else {
    // 旧形式（後方互換性のため）
    if (args.length < 2) {
      console.error('エラー: アルバム名が指定されていません');
      console.error('使い方: node fetch_album_producers.js <Genius アルバムURL>');
      process.exit(1);
    }
    artistName = args[0];
    albumName = args[1];
    albumUrl = `https://genius.com/albums/${artistName}/${albumName}`;
  }
  
  console.log(`\n=== プロデューサー情報を取得中 ===\n`);
  
  try {
    const { results, artistName: extractedArtist, albumName: extractedAlbum } = await fetchAlbumProducers(albumUrl);
    
    // 表示用の名前を設定
    const displayArtist = artistName || extractedArtist;
    const displayAlbum = albumName || extractedAlbum;
    
    if (results.length === 0) {
      console.error('曲が見つかりませんでした。URLを確認してください。');
      process.exit(1);
    }
    
    // 結果をテキストファイルに出力
    let output = `アルバム「${displayAlbum}」- ${displayArtist}\n`;
    output += `取得日時: ${new Date().toLocaleString('ja-JP', { timeZone: 'Asia/Tokyo' })}\n`;
    output += `総曲数: ${results.length}曲\n`;
    output += '='.repeat(60) + '\n\n';
    
    results.forEach(track => {
      output += `${track.number}. ${track.title}\n`;
      output += `   Producer: ${track.producer}\n\n`;
    });
    
    // プロデューサーごとの担当曲番号を集計
    output += '\n' + '='.repeat(60) + '\n';
    output += 'プロデューサー別担当曲一覧\n';
    output += '='.repeat(60) + '\n\n';
    
    const producersByTrack = aggregateProducersByTrack(results);
    producersByTrack.forEach(([producer, trackNumbers]) => {
      output += `${producer}(${trackNumbers.join(',')})\n`;
    });
    
    // 出力ディレクトリを作成
    const outputDir = 'BOB/Bob_output';
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }
    
    // ファイル名を生成（アーティスト名とアルバム名から）
    const safeArtistName = displayArtist.toLowerCase().replace(/[^a-z0-9]/g, '_');
    const safeAlbumName = displayAlbum.toLowerCase().replace(/[^a-z0-9]/g, '_');
    const filename = `${outputDir}/${safeArtistName}_${safeAlbumName}_producers.txt`;
    fs.writeFileSync(filename, output, 'utf8');
    
    console.log(`\n結果を ${filename} に保存しました\n`);
    console.log('--- 取得結果 ---');
    console.log(output);
    
  } catch (error) {
    console.error('エラーが発生しました:', error.message);
    process.exit(1);
  }
}

main();

// Made with Bob
