# Code Review: `miguel4.htm`

**planet.KY — Miguel / CAOS CDレビューページ**  
450行 ｜ HTML4 / Dreamweaver 6 テンプレート構成

---

## サマリー

| 重要度 | 件数 |
|--------|------|
| 🔴 High   | 4 |
| 🟡 Medium | 5 |
| 🔵 Low    | 4 |
| ℹ️ Info   | 3 |
| **合計**  | **16** |

---

## 🔴 High — セキュリティ・パフォーマンス上の問題

### H-1　`eval()` を使った XSS リスク（行 25–28）

**カテゴリ:** Security

```js
function MM_jumpMenu(targ,selObj,restore){ //v3.0
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
}
```

`eval()` に外部文字列を直接渡している。`selObj.options[…].value` が攻撃者によって
操作された場合、任意スクリプトを実行できる。また `targ` は文字列 `"parent"` の固定値
なのに `eval` を使う必要がない。

**修正案:**

```js
function MM_jumpMenu(selObj, restore) {
  var url = selObj.options[selObj.selectedIndex].value;
  if (url) parent.location = url;
  if (restore) selObj.selectedIndex = 0;
}
```

> 呼び出し側も `onchange="MM_jumpMenu(this,1)"` に変更が必要。

---

### H-2　`Content-Type` の重複宣言（行 20, 32）

**カテゴリ:** Security / Encoding

```html
<!-- 行20 --> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<!-- 行32 --> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
```

同じメタタグが2回宣言されている（テンプレート残骸）。現在はどちらも UTF-8 なので
実害はないが冗長。**行 32 を削除すること。**

---

### H-3　HTTP / プロトコル相対 URL の混在（行 49, 218, 406）

**カテゴリ:** Security

| 行 | URL | 問題 |
|----|-----|------|
| 49 | `//ck.jp.ap.valuecommerce.com/…` | プロトコル相対 URL。HTTPS ページ上で HTTP に解決されるとブロックされる可能性がある。`https://` に明示すること。 |
| 49 | `//ad.jp.ap.valuecommerce.com/…` | 同上（広告画像） |
| 218 | `http://planetky.com` | サイトが HTTPS 対応なら `https://` に統一すること。 |
| 406 | `http://officialmiguel.com` | 外部リンクも `https://` を推奨。 |

---

### H-4　`document.write()` によるレンダリングブロッキング（行 140, 223）

**カテゴリ:** Performance

```js
document.write(imgFile2);                              // 行140
document.write('Last updated at ', document.lastModified); // 行223
```

`document.write()` はパーサーをブロックしページロードを遅延させる。
Google も Core Web Vitals への悪影響を理由に廃止を推奨している。

**修正案（サムネイル・行 135–141）:**

```html
<div id="thumb-mid"></div>
<script>
  var f = location.href.split('/').pop().split('.').shift() + "M.jpg";
  document.getElementById('thumb-mid').innerHTML =
    '<img src="gif/' + f + '" width="75" alt="">';
</script>
```

**修正案（最終更新日・行 222–224）:**

```html
<span id="last-mod"></span>
<script>
  document.getElementById('last-mod').textContent =
    'Last updated at ' + document.lastModified;
</script>
```

---

## 🟡 Medium — 標準準拠・品質の問題

### M-1　非推奨・廃止属性の多用

**カテゴリ:** Deprecation

| 行 | コード | 代替 |
|----|--------|------|
| 39 | `<font color="…" size="-1">` | CSS の `color` / `font-size` |
| 38, 244… | `border="0"` (img 属性) | `bm1.css` に `img { border: none; }` が定義済みなので属性は不要 |
| 277–278 | `<FONT size=-2>`, `<font face="Arial">` | CSS クラスで指定 |
| 23, 135, 222 | `<script language="JavaScript">` | `<script>`（`language` 属性は HTML4 でも非推奨） |
| 294, 301… | `align="right"` (td 属性) | CSS `text-align: right` |

---

### M-2　`name="form1"` の重複（行 64, 96）

**カテゴリ:** HTML Validity

同一ページ内に `name="form1"` を持つ `<form>` が2つある。
`name` 属性はページ内で一意にすること。

**修正案:**
```html
<form name="form-album-year">…</form>
<form name="form-best-year">…</form>
```

---

### M-3　Apple Music iframe の `sandbox` 過剰権限（行 234）

**カテゴリ:** Security

```html
sandbox="allow-forms allow-popups allow-same-origin allow-scripts allow-top-navigation-by-user-activation"
```

`allow-top-navigation-by-user-activation` は iframe 内スクリプトがユーザー操作後に
親ページの URL を書き換えることを許す。外部音楽プレイヤーに付与するのは過剰な権限。
Apple Music の公式埋め込みコードが推奨する最小限のフラグに揃えること。

---

### M-4　UA（Universal Analytics）が計測終了済み（行 5, 11）

**カテゴリ:** Analytics

```js
gtag('config', 'UA-54911-2');
```

Universal Analytics は **2023年7月に計測終了**。このタグはデータを収集しなくなっている。
GA4 プロパティ（`G-XXXXXXXXXX`）へ移行が必要。

---

### M-5　ValueCommerce 広告画像に `alt` 属性なし（行 49）

**カテゴリ:** Accessibility

```html
<img src="//ad.jp.ap.valuecommerce.com/…" border="0">
```

装飾・広告画像でも `alt=""` (空文字) を付与してスクリーンリーダーにスキップを指示すること。

---

## 🔵 Low — コード品質・保守性

### L-1　`EditRegion1` プレースホルダが残存（行 229）

**カテゴリ:** Dead Code

```html
<!-- #BeginEditable "EditRegion1" -->EditRegion1<!-- #EndEditable -->
```

Dreamweaver テンプレートの編集可能領域テキスト `EditRegion1` がそのままレンダリングされている。
実際のコンテンツを入れるか、不要なら空にすること。

---

### L-2　`<tbody>` の二重開きタグ（テーブル構造破損）（行 275, 436）

**カテゴリ:** HTML Validity

`.t3` テーブル内で `<tbody>` が2回開かれており、最初の `</tbody>` が存在しない。
ブラウザは自動補正するが仕様違反。

```html
行275: <tbody>
  ...（行436まで </tbody> なし）
行436: <tbody>  ← 閉じずに再オープン
```

**修正:** 行 436 を `</tbody>` に変更する。

---

### L-3　`tr-left` クラスが `bm1.css` で未定義（行 37）

**カテゴリ:** CSS

```html
<tr class="tr-left">
```

`bm1.css` に `.tr-left` の定義が存在しない（`.tr-center` は存在する）。
意図した効果が出ていない可能性がある。確認して修正または削除すること。

---

### L-4　トラックテーブルのヘッダ行に `<th>` 未使用（行 286–292）

**カテゴリ:** Accessibility / Semantics

```html
<tr>
  <td>No.</td>
  <td>Title</td>
  <td>Composer</td>
  <td>Performer</td>
  <td>Time</td>
</tr>
```

テーブルのヘッダ行には `<th scope="col">` を使うべき。
スクリーンリーダーおよび SEO の両面で有益。

---

## ℹ️ Info — 情報・将来への注意

### I-1　Amazon Associates 1×1px ビーコン（旧形式）（行 39）

```html
<img src="https://www.assoc-amazon.com/e/ir?t=webky&l=ur2&o=1" width="1" height="1" …>
```

旧来の Amazon Associates 画像ビーコン形式。現在のアフィリエイトプログラムでは
不要になっている場合が多い。最新仕様を確認し、不要であれば削除すること。

---

### I-2　Dreamweaver ライブラリアイテムの静的展開コスト

ナビゲーション（`BMMenu2.lbi`）が各ページに静的展開されているため、
リンクの追加・変更時はサイト内の全ページを一括再生成する必要がある。
SSI（Server Side Includes）または JavaScript による動的挿入への移行を検討する価値がある。

---

### I-3　CSS で単位なし数値（`bm1.css` 行 150, 158）

```css
border-spacing: 3;   /* → 3px */
padding: 2;          /* → 2px */
```

CSS では数値に単位が必要（例外は `0` のみ）。
一部ブラウザでは無視される可能性がある。`3px` / `2px` に修正すること。

---

## 修正優先度まとめ

| 優先 | 問題 | 重要度 | 工数 |
|------|------|--------|------|
| 1 | `eval()` 削除 → `MM_jumpMenu` 修正（H-1） | 🔴 High | 小 |
| 2 | `Content-Type` 重複宣言 行32 削除（H-2） | 🔴 High | 極小 |
| 3 | HTTP → HTTPS / プロトコル相対 URL 修正（H-3） | 🔴 High | 小 |
| 4 | `document.write()` 撤廃（H-4） | 🔴 High | 小 |
| 5 | GA4 への移行（M-4） | 🟡 Medium | 小 |
| 6 | `<tbody>` 二重開きタグ修正（L-2） | 🔵 Low | 極小 |
| 7 | `EditRegion1` プレースホルダ除去（L-1） | 🔵 Low | 極小 |
| 8 | `form name` 重複修正（M-2） | 🟡 Medium | 極小 |
| 9 | 廃止 HTML 属性の CSS 移行（M-1） | 🟡 Medium | 中 |
| 10 | トラック表に `<th>` 使用（L-4） | 🔵 Low | 極小 |
| 11 | `bm1.css` の単位なし数値修正（I-3） | ℹ️ Info | 極小 |
