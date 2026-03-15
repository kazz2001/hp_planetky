import requests
from bs4 import BeautifulSoup
import json
import re

def scrape_album_info(album_url):
    """
    Apple MusicのアルバムページからトラックIDを抽出
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        response = requests.get(album_url, headers=headers)
        response.raise_for_status()
        
        # HTMLからJSONデータを抽出
        html_content = response.text
        
        # ページ内のJSONデータを探す
        # Apple Musicは通常、ページ内にJSONデータを埋め込んでいます
        json_pattern = r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>'
        json_matches = re.findall(json_pattern, html_content, re.DOTALL)
        
        # または、window.INITIAL_STATE のようなグローバル変数を探す
        state_pattern = r'window\.__INITIAL_STATE__\s*=\s*({.*?});'
        state_matches = re.findall(state_pattern, html_content, re.DOTALL)
        
        if state_matches:
            try:
                initial_state = json.loads(state_matches[0])
                print("Initial state found!")
                print(json.dumps(initial_state, indent=2)[:500])
            except json.JSONDecodeError:
                print("Failed to parse initial state")
        
        # トラックIDのパターンを探す
        track_id_pattern = r'"id":"(\d+)"'
        track_ids = re.findall(track_id_pattern, html_content)
        
        if track_ids:
            print(f"Found {len(track_ids)} potential track IDs")
            for idx, track_id in enumerate(track_ids[:20], 1):  # 最初の20個を表示
                print(f"{idx}. Track ID: {track_id}")
        
        return track_ids
        
    except Exception as e:
        print(f"Error: {e}")
        return None

def generate_credit_urls_manual():
    """
    手動で確認したトラック情報からクレジットURLを生成
    """
    album_id = "1824330589"
    
    # Through The Wall アルバムのトラックリスト
    # これらは手動で確認する必要があります
    tracks = [
        {"number": 1, "name": "Grace", "track_id": ""},
        {"number": 2, "name": "Ladida", "track_id": ""},
        {"number": 3, "name": "Sum", "track_id": ""},
        {"number": 4, "name": "The Boy", "track_id": ""},
        {"number": 5, "name": "Doing It Too", "track_id": ""},
        {"number": 6, "name": "Never Enough", "track_id": ""},
        {"number": 7, "name": "Words 2 Say", "track_id": ""},
        {"number": 8, "name": "Bite The Bait", "track_id": ""},
        {"number": 9, "name": "On 2 Something", "track_id": ""},
    ]
    
    print("Through The Wall - Rochelle Jordan")
    print("="*80)
    print()
    print("各曲のクレジットURLパターン:")
    print()
    
    for track in tracks:
        # トラックIDが不明な場合のプレースホルダー
        if track["track_id"]:
            credit_url = f"https://music.apple.com/us/album/through-the-wall/{album_id}?i={track['track_id']}"
        else:
            credit_url = f"https://music.apple.com/us/album/through-the-wall/{album_id}?i=[TRACK_ID_NEEDED]"
        
        print(f"{track['number']}. {track['name']}")
        print(f"   URL: {credit_url}")
        print()
    
    print("="*80)
    print("\n注: [TRACK_ID_NEEDED] の部分は、実際のトラックIDに置き換える必要があります。")
    print("トラックIDを取得するには:")
    print("1. ブラウザでアルバムページを開く")
    print("2. 開発者ツール (F12) を開く")
    print("3. 各曲をクリックして、URLに表示される '?i=' の後の数字を確認")
    
    return tracks

if __name__ == "__main__":
    album_url = "https://music.apple.com/us/album/through-the-wall/1824330589"
    
    print("Apple Music アルバム情報スクレイピング")
    print("="*80)
    print()
    
    # スクレイピングを試みる
    print("アルバムページからトラックIDを抽出中...")
    print()
    track_ids = scrape_album_info(album_url)
    
    print("\n" + "="*80 + "\n")
    
    # 手動確認用のテンプレートを生成
    generate_credit_urls_manual()

# Made with Bob
