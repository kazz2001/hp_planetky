
# HTMLドラフト作成 Bob\genius_album_to_html.ps1

```powershell
powershell -ExecutionPolicy Bypass -File "Bob\genius_album_to_html.ps1" -AlbumUrl "<Genius アルバム URL>" [-OutputFilePrefix "<ファイル名>"]
```
# メタタグ, TitleをCopyする。

# トラックリストを洗練する 
```
Bob\allmusic_track_scraper.js
```
```bash
# デフォルトのファイル名で出力
node Bob/allmusic_track_scraper.js https://www.allmusic.com/album/addison-mw0004526525

# カスタムファイル名で出力
node Bob/allmusic_track_scraper.js https://www.allmusic.com/album/addison-mw0004526525 my_album_tracks.html
```
# Producerを洗練する
```
Bob\fetch_album_producers.js

```
# レビューする。
```
/review ファイル名
```

# index.htmlのバックアップをとってから、先頭にjid2.htm"の内容を追加して。次に、最後のエントリーは削除して。

# oliviadean1.htmのMetaタグの内容をupdateして。  不要

# レビュー

Genius API
Client ID
1UovcPrC5QtD-AY6DwGsIy98mzNHXFo9UYAd3AaBshre4gcl0tV7fKwCGytpWNTb

Client Secret
vQJfyEiIMKllBy4xEe3ZeY7R4yd37MdMJmOs2thbVeQnMcY8yBoh91_1nxlOJTGd6x1E6NRYwVcM9VsxEB_YRg

Access Token
7yNKHpRUHuMZR2G1Uxiy6a7eumS6RtRIqLkbbZR34Oy9DXGfW1J3Bwz4y9WnPKRk