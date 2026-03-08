# genius_album_to_html.ps1

Genius.com のアルバムページから曲情報を自動取得し、planet.KY サイト用の CD レビュー HTML ファイルを生成する PowerShell スクリプト。

---

## 必要環境

- Windows PowerShell 5.1 以上（または PowerShell 7+）
- インターネット接続
- .NET の `System.Web` アセンブリ（Windows 標準搭載）

---

## 使い方

```powershell
powershell -ExecutionPolicy Bypass -File "Bob\genius_album_to_html.ps1" -AlbumUrl "<Genius アルバム URL>"
```

### 例

```powershell
powershell -ExecutionPolicy Bypass -File "Bob\genius_album_to_html.ps1" -AlbumUrl "https://genius.com/albums/Jim-legxacy/Black-british-music-2025"
```

---

## パラメーター

| パラメーター | 必須 | 説明 |
|---|---|---|
| `-AlbumUrl` | ✅ | Genius.com のアルバムページ URL（例: `https://genius.com/albums/Artist-Name/Album-Name`） |

---

## 出力

- 出力先: `Bob\output\{アーティスト名}1_tracks.htm`
- ファイル名はアーティスト名から英数字のみ抽出して小文字化したもの（例: `jimlegxacy1_tracks.htm`）
- エンコーディング: UTF-8

---

## 生成される HTML の内容

planet.KY の `CDREVIEWU.dwt` テンプレートに準拠した HTML ファイルが生成されます。

| セクション | 内容 |
|---|---|
| **Score Card** | ラップ/歌、アーバン/アーシー、聴きやすい/シリアス、評点（初期値は空欄） |
| **Tracks テーブル** | No. / Title / Composer / Performer / Time の5列 |
| **Producers** | プロデューサー名と担当トラック番号 |
| **Guests** | フィーチャリングアーティストと担当トラック番号 |
| **Links** | Genius アルバムページへのリンク |
| **Other Reviews** | 空欄（手動入力用） |

---

## 動作の仕組み

1. **アルバムページ取得**  
   指定 URL から HTML を取得し、`<title>` タグよりアーティスト名・アルバム名を抽出。

2. **トラック URL 一覧取得**  
   アルバムページ内の `-lyrics` リンクを正規表現で抽出。アーティストのスラッグで始まる URL のみを対象とし、他アーティストの曲や広告リンクを除外。

3. **各トラックの情報取得**  
   各曲ページを取得し、以下を抽出：
   - **タイトル**: `<title>` タグから「アーティスト – 曲名」形式を解析
   - **Song ID**: HTML 内の JSON データから抽出

4. **Genius API 呼び出し**  
   `https://genius.com/api/songs/{songId}` を呼び出し、JSON レスポンスから取得：
   - `writer_artists` → Composer 列
   - `producer_artists` → Producers セクション
   - `featured_artists` → Performer 列・Guests セクション

5. **HTML 生成・出力**  
   取得した情報を元に HTML を組み立て、UTF-8 で出力。

---

## 注意事項

- **レート制限対策**: 各トラック取得後に 300ms のスリープを挿入しています。トラック数が多い場合は時間がかかります。
- **Genius API 認証不要**: 公開 API エンドポイントを使用しているため、API キーは不要です。
- **アーティストスラッグのフィルタリング**: アルバム URL の `/albums/{slug}/` 部分を使ってトラックを絞り込みます。コラボアルバムなど、スラッグが曲 URL と一致しない場合は全曲が取得されない可能性があります。
- **手動編集が必要な箇所**:
  - アルバムジャケット画像: `gif/{アーティスト名}1L.jpg` を別途用意
  - Score Card の評点・スコアバー画像
  - レーベル名
  - アルバム解説文（Score Card の Y 領域）
  - Apple Music 等の埋め込みプレーヤー

---

## フォールバック動作

| 状況 | 対応 |
|---|---|
| Genius API 取得失敗 | HTML の `was written by` セクションから Writer を抽出 |
| API で Producer が取得できない | HTML の `Producers` クレジットセクションから抽出 |
| `System.Net.WebClient` 失敗 | `Invoke-WebRequest` にフォールバック |
| タイトル取得失敗 | URL スラッグから曲名を補完 |

---

## ファイル構成

```
Bob/
├── genius_album_to_html.ps1   # 本スクリプト
├── README_genius_album_to_html.md  # このファイル
└── output/
    └── {アーティスト}1_tracks.htm  # 生成された HTML
```

---

## 生成後の作業手順

1. `Bob\output\{アーティスト}1_tracks.htm` を確認・編集
2. `gif\` フォルダにアルバムジャケット画像（`{アーティスト}1L.jpg`, `{アーティスト}1M.jpg`）を配置
3. Score Card の評点・スコアバー画像を設定
4. レーベル名・解説文を追記
5. 完成したファイルをサイトルートにコピー（例: `jimlegxacy1.htm`）
6. `index.html` の Latest CD Reviews セクションにエントリーを追加