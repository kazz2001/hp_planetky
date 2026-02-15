# AllMusic Track Scraper

AllMusicのアルバムページからトラックリスト情報（曲名、作曲者、演奏者、時間）を取得し、HTMLテーブルとして出力するNode.jsスクリプトです。

## 機能

- AllMusicのアルバムページURLからトラック情報を自動取得
- 各曲の詳細ページから作曲者（Composer）情報を抽出
- 演奏者（Performer）情報を取得
- 曲の長さを読みやすい形式（例: 2:34）に変換
- HTMLテーブル形式で整形されたトラックリストを生成
- レート制限を考慮した自動待機機能

## 必要要件

- Node.js（v12以上推奨）
- インターネット接続

## インストール

このスクリプトは標準のNode.jsモジュール（`https`, `fs`）のみを使用しているため、追加のパッケージインストールは不要です。

## 使用方法

### 基本的な使い方

```bash
node allmusic_track_scraper.js <AllMusic Album URL> [output_file.html]
```

### パラメータ

- `<AllMusic Album URL>` (必須): AllMusicのアルバムページのURL
- `[output_file.html]` (オプション): 出力ファイル名（デフォルト: `track_listing.html`）

### 使用例

```bash
# デフォルトのファイル名で出力
node allmusic_track_scraper.js https://www.allmusic.com/album/addison-mw0004526525

# カスタムファイル名で出力
node allmusic_track_scraper.js https://www.allmusic.com/album/addison-mw0004526525 my_album_tracks.html
```

## 出力形式

スクリプトは以下の情報を含むHTMLテーブルを生成します：

| 項目 | 説明 |
|------|------|
| No. | トラック番号 |
| Title | 曲名 |
| Composer | 作曲者（複数の場合は " / " で区切られる） |
| Performer | 演奏者 |
| Time | 曲の長さ（分:秒形式） |

### 出力例

生成されるHTMLファイルには、スタイル付きのテーブルが含まれます：

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Album Title - Track Listing</title>
    <style>
        /* スタイル定義 */
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
                        <!-- トラック情報 -->
                    </tbody>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
```

## 実行時の動作

1. **アルバムページの取得**: 指定されたURLからアルバム情報を取得
2. **トラック情報の抽出**: JSON-LDデータからトラックリストを解析
3. **作曲者情報の取得**: 各曲の詳細ページから作曲者情報を取得（1秒間隔で実行）
4. **HTMLファイルの生成**: 取得した情報を整形してHTMLファイルとして保存
5. **コンソール出力**: トラックリストの概要を表示

### 実行例の出力

```
アルバムページを取得中: https://www.allmusic.com/album/addison-mw0004526525
トラック情報を抽出中...

各曲のComposer情報を取得中（全12曲）...
1/12: Track Title 1
2/12: Track Title 2
...

HTMLテーブルを生成中...

✓ HTMLファイルを作成しました: track_listing.html

=== トラックリスト（全12曲）===
 1. Track Title 1
    Composer: John Doe
    Duration: 3:45
 2. Track Title 2
    Composer: Jane Smith / Bob Johnson
    Duration: 4:12
...
```

## 主要な関数

### `convertDuration(duration)`
PT00H02M34S形式の時間を2:34形式に変換します。

### `fetchPage(url)`
HTTPSリクエストを実行してHTMLを取得します。

### `getComposer(url)`
各曲のページから作曲者情報を抽出します。

### `extractTracks(html)`
アルバムページのHTMLからJSON-LD形式のトラック情報を抽出します。

### `generateHtmlTable(trackData, albumTitle)`
トラックデータからHTMLテーブルを生成します。

## 注意事項

- **レート制限**: AllMusicサーバーへの負荷を軽減するため、各曲の情報取得の間に1秒の待機時間を設けています
- **エラーハンドリング**: 作曲者情報が取得できない場合は "Unknown" と表示されます
- **User-Agent**: スクリプトはブラウザのUser-Agentを使用してリクエストを送信します
- **利用規約**: AllMusicの利用規約を遵守してください

## トラブルシューティング

### トラック情報が見つからない場合
- URLが正しいか確認してください
- AllMusicのページ構造が変更されている可能性があります

### 作曲者情報が "Unknown" になる場合
- 該当曲のページに作曲者情報が存在しない可能性があります
- ネットワーク接続を確認してください

### エラーが発生する場合
```bash
# デバッグ情報を確認
node allmusic_track_scraper.js <URL> 2>&1 | tee debug.log
```

## ライセンス

このスクリプトは個人利用を目的としています。AllMusicのコンテンツは各権利者に帰属します。

## 作成者

Made with Bob

## 更新履歴

- 初版: AllMusicからのトラック情報取得機能を実装