# Apple Music Credits Extractor

## 概要

[`extract_apple_music_credits.ps1`](Bob/extract_apple_music_credits.ps1) は、[`credit.MD`](Bob/credit.MD) に記載した Apple Music の曲URLから、各曲の以下の情報を抽出して一覧化する PowerShell スクリプトです。

- Composer
- Producer
- Performer

出力先は [`output/selected_tracks_credits.md`](Bob/output/selected_tracks_credits.md) です。

## 入力ファイル

入力ファイルは [`credit.MD`](Bob/credit.MD) です。  
1行に1つずつ Apple Music の曲URLを記載します。

例:

```text
https://music.apple.com/jp/song/youugly/1812517699
https://music.apple.com/jp/song/glory/1812517941
https://music.apple.com/jp/song/wrk/1812517944
```

## 実行方法

PowerShell で [`Bob`](Bob/) 配下にあるスクリプトを実行します。

```powershell
powershell -ExecutionPolicy Bypass -File .\Bob\extract_apple_music_credits.ps1
```

## 出力ファイル

実行後、結果は [`output/selected_tracks_credits.md`](Bob/output/selected_tracks_credits.md) に保存されます。

出力例:

```md
# Selected Tracks Credits

- YouUgly
  - Composer: Luke Crowder, Destin Route
  - Producer: Tú
  - Performer: JID, Westside Gunn
```

## 補足

- スクリプトは [`credit.MD`](Bob/credit.MD) 内の URL 行のみを対象にします。
- 出力先ディレクトリ [`output`](Bob/output/) が存在しない場合は自動で作成します。
- Producer は Apple Music のクレジット内で「プロデューサー」と判定された項目のみを抽出します。