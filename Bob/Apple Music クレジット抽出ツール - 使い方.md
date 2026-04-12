# Apple Music クレジット抽出ツール 🎵

Apple Musicの楽曲ページから、作曲者・プロデューサー・パフォーマーのクレジット情報を抽出するPowerShellツールです。

---

## 📋 できること

このツールは、Apple Musicの曲URLから以下の情報を抽出します：

- **Composer（作曲者）** - 楽曲を作曲した人 ✅ 自動取得
- **Producer（プロデューサー）** - 楽曲を制作した人 ⚠️ 手動入力が必要
- **Performer（パフォーマー）** - 楽曲を演奏・歌唱した人 ✅ 自動取得

複数の曲を一度に処理して、見やすいMarkdown形式で出力します。

> **注意**: Apple Musicのページ構造の変更により、Producer情報は現在自動取得できません。出力ファイルに `**[MANUAL INPUT REQUIRED]**` と表示されますので、手動で追加してください。

---

## 🚀 使い方

### ステップ1: URLを準備する

`credit.MD` ファイルに、調べたい曲のApple Music URLを1行ずつ記載します。

**例：**
```
https://music.apple.com/jp/song/youugly/1812517699
https://music.apple.com/jp/song/glory/1812517941
https://music.apple.com/jp/song/wrk/1812517944
```

### ステップ2: スクリプトを実行する

PowerShellで以下のコマンドを実行します：

```powershell
powershell -ExecutionPolicy Bypass -File .\Bob\extract_apple_music_credits.ps1
```

または、Bobフォルダ内で直接実行：

```powershell
cd Bob
.\extract_apple_music_credits.ps1
```

### ステップ3: 結果を確認する

`output/selected_tracks_credits.md` に結果が保存されます。

---

## 📄 出力例

```markdown
# Selected Tracks Credits

### Community

- **Composer**: Destin Route, TERRENCE THORNTON, ジェネ・ソーントン, Frank Parra, M. Dragoi
- **Producer**: **[MANUAL INPUT REQUIRED]**
- **Performer**: JID, プッシャ・T, マリス, Jabrielle Williams

### Gz

- **Composer**: Destin Route, John Welch, Shakari Linder
- **Producer**: **[MANUAL INPUT REQUIRED]**
- **Performer**: JID, Trakgirl, カイロ
```

Producer情報は、Apple Musicのページで確認して手動で追加してください。

---

## 📁 ファイル構成

```
Bob/
├── extract_apple_music_credits.ps1  ← メインスクリプト
├── credit.MD                        ← 入力ファイル（URLリスト）
├── Apple Music クレジット抽出ツール - 使い方.md  ← このファイル
└── output/
    └── selected_tracks_credits.md   ← 出力ファイル
```

---

## ⚙️ 技術的な詳細

### 動作環境
- Windows PowerShell 5.1以降
- インターネット接続が必要

### 文字エンコーディング
- 入力・出力ともにUTF-8（BOM付き）
- 日本語を含むクレジット情報も正しく処理されます

### エラー処理
- URLが無効な場合はエラーメッセージを表示
- `output`フォルダが存在しない場合は自動作成

---

## 💡 Tips

- **複数の曲を一度に処理**: `credit.MD`に何行でもURLを追加できます
- **重複の自動除去**: 同じ名前が複数回出現しても、自動的に1つにまとめられます
- **日本語対応**: 日本語のアーティスト名やクレジット情報も正しく表示されます
- **Producer情報の追加方法**: 出力ファイルの `**[MANUAL INPUT REQUIRED]**` を、Apple Musicページで確認したProducer名に置き換えてください

---

## 🔧 トラブルシューティング

### 文字化けする場合
スクリプトは既にUTF-8エンコーディングに対応していますが、もし文字化けが発生する場合は：
1. PowerShellを管理者権限で実行
2. 出力ファイルをUTF-8対応のエディタ（VS Code等）で開く

### スクリプトが実行できない場合
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
を実行してから、再度スクリプトを実行してください。

---

## 📝 更新履歴

- **2026-04-05**:
  - 文字化け問題を修正（UTF-8エンコーディング対応）
  - 出力形式を改善（Markdown見出しとボールド表示）
  - Producer情報は手動入力が必要な旨を明記
- 初版リリース

---

Made with ❤️ by Bob