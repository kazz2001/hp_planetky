# アルバムレビュー作成 ワークフロー (To Do List)

アルバムレビューページ作成・更新の手順とコマンド・プロンプト一覧です。

---

## 📋 作業チェックリスト

- [ ] **Step 1: HTMLドラフトの作成 (Genius)**
- [ ] **Step 2: メタタグ・Titleのコピー / Apple Music リンクの作成**
- [ ] **Step 3: トラックリストの取得・反映**
- [ ] **Step 4: Producerリストの抽出・反映**
- [ ] **Step 5: Guestリストの作成・反映**
- [ ] **Step 6: アルバムレビューの執筆**
- [ ] **Step 7: ファイル名・ページの最終レビュー**
- [ ] **Step 8: index.html への追加と更新**

---

## 🛠️ 各ステップ詳細とコマンド / プロンプト

### 1. HTMLドラフト作成 (`Bob\genius_album_to_html.ps1`)
Genius API（Bearer Token）を利用してアルバム情報・トラックリスト・クレジット（作詞/作曲/Producer/Guest）を取得し、ドラフトHTMLを生成します。

> **Note:** Genius API トークンは環境変数 `GENIUS_ACCESS_TOKEN` から自動取得されます（オプションで `-GeniusToken "<トークン>"` を渡すことも可能）。

```powershell
powershell -ExecutionPolicy Bypass -File "Bob\genius_album_to_html.ps1" -AlbumUrl "<Genius アルバム URL>" [-OutputFilePrefix "<ファイル名>"]
```

---

### 2. メタタグ・Titleのコピー & Apple Music リンク作成
- 既存の類似ページやテンプレートから、適切なメタタグ（`meta description` / `keywords`）および `<title>` をコピー・設定します。
- Apple Music へのリンクを作成・設定します。

---

### 3. トラックリストを洗練する

#### A. NotebookLM を使用する場合
1. NotebookLM で `/tracks` を実行してトラック情報を抽出。
2. 以下のプロンプトでトラックテーブルを置換:
   > `file1=Bob\output\<ファイル名>_tracks.htm`  
   > `Bob\output\track.mdの内容で、file1のTracksセクションのテーブルの内容を置き替えて。列名はfile1のままで。曲順、曲名はBob\output\track.mdが正しいです。`

#### B. AllMusic Scraper を使用する場合 (`Bob\allmusic_track_scraper.js`)
```bash
# デフォルトのファイル名で出力
node Bob/allmusic_track_scraper.js <AllMusic アルバム URL>

# カスタムファイル名で出力
node Bob/allmusic_track_scraper.js <AllMusic アルバム URL> my_album_tracks.html
```

---

### 4. Producerを洗練する (`Bob\fetch_album_producers.js`)

1. プロデューサー情報を取得・集計。
2. 以下の形式でプロデューサーリストを出力・反映:
   ```text
   以下の形式でProducerのリストを出力して
   Pro1(1)
   Pro2 and Pro3(2,3)
   Pro1, Pro3 and Pro4(4)
   ```

---

### 5. Guestのリストを作る

以下のカンマ区切り形式でゲストリストを作成・反映:
```text
Guest1, Guest2, Guest3
```

---

### 6. アルバムレビューを書く
- NotebookLM で `/review` を実行し、レビュー本文を作成・推敲。
- Copilotでレビューする。

---

### 7. ファイル・ページのレビュー
- 生成・編集したHTMLファイルの内容および命名規則を確認。
  > プロンプト例: `ファイル名をレビューして`

---

### 8. index.html に追加

以下のプロンプトを使用して [`index.html`](index.html) を更新します:

```text
【アルバムレビューのページ】= <作成したHTMLファイル名>
index.htmlのバックアップをとってから、先頭に【アルバムレビューのページ】の内容を追加して。次に、最後のエントリーは削除して。リンクは【アルバムレビューのページ】にして。レビューコメントも【アルバムレビューのページ】からそのままコピーして。
```

---

## 🔑 認証情報 (Genius API)

| 項目 | 値 | 備考 |
| :--- | :--- | :--- |
| **Client ID** | `1UovcPrC5QtD-AY6DwGsIy98mzNHXFo9UYAd3AaBshre4gcl0tV7fKwCGytpWNTb` | |
| **Client Secret** | `vQJfyEiIMKllBy4xEe3ZeY7R4yd37MdMJmOs2thbVeQnMcY8yBoh91_1nxlOJTGd6x1E6NRYwVcM9VsxEB_YRg` | |
| **Access Token** | `7yNKHpRUHuMZR2G1Uxiy6a7eumS6RtRIqLkbbZR34Oy9DXGfW1J3Bwz4y9WnPKRk` | ユーザー環境変数 `GENIUS_ACCESS_TOKEN` に登録済み |
