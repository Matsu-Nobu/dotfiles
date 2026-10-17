# Confluence ページの編集

## 本文の投入形式は html だけを使う

`updateConfluencePage` / `createConfluencePage` の `bodyFormat` には `html`、`markdown`、`adf` を指定できるが、**本文として解析されるのは `html` だけである**。`markdown` と `adf` を指定すると、渡した文字列が解析されずにそのまま平文としてページに入る。マークダウン記法なら記号が見えたままになり、ADF なら JSON がそのまま表示される。

取得側の `contentFormat` には `markdown` が使えるので、読むときは `markdown`、書くときは `html` と覚える。読み書きで形式が違うことがこの間違いの原因になる。

## 使える html の範囲

見出し (`h1`〜`h6`)、段落 (`p`)、箇条書き (`ul` / `ol` / `li`)、表 (`table` / `tbody` / `tr` / `th` / `td`)、強調 (`strong` / `em`)、インラインコード (`code`)、リンク (`a`)、改行 (`br`)、区切り線 (`hr`) が使える。表のセル内で改行したいときは `<br/>` を入れる。

Confluence 独自の要素は `data-type` 属性で表現する。情報パネルは `<div data-type="panel-info"><p>本文</p></div>`、ステータスラベルは `<span data-type="status" data-color="green">Done</span>`、Mermaid 図は `<pre><code class="language-mermaid">flowchart LR\n  A--&gt;B</code></pre>` と書く。

## ページと表とコードブロックは最大の幅にする

Claude は、Confluence にページを作ったら、そのページの幅を最大にする。ページの幅は本文ではなく、ページのプロパティ `content-appearance-published` と `content-appearance-draft` に保存されているので、`createConfluencePage` と `updateConfluencePage` では変えられない。Claude は、ページを作った直後に `~/.claude/bin/confluence-max-width.sh <ページの ID>` を実行する。このスクリプトは、Confluence の REST API v2 で、2 つのプロパティの値を、エディタで最大の幅を選んだときの値 `max` にする。

Claude は、ページに置くすべての表を `<table data-layout="full-width">` と書き、すべてのコードブロックを `<pre data-breakout="full-width">` と書いて、どちらもページの全幅で表示させる。

## マクロは data-type="extension" で書く

目次のようなマクロは `data-type="extension"` と `data-extension-key` の組み合わせで表す。マクロ名を `data-type` に直接書く形（`<div data-type="toc">`）や、ストレージ形式（`<ac:structured-macro ac:name="toc"/>`）は拒否される。

目次の場合は次のとおり。

```
<div data-type="extension" data-extension-key="toc"
     data-extension-type="com.atlassian.confluence.macro.core" data-layout="default"
     data-parameters="{&quot;macroParams&quot;:{&quot;style&quot;:{&quot;value&quot;:&quot;none&quot;}}}"></div>
```

他のマクロを書きたいときは、そのマクロを含む既存ページを `contentFormat: html` で取得して、生成されている属性をそのまま写す。属性の綴りを推測してはならない。

## マクロは markdown 形式では見えない

`contentFormat: markdown` で取得すると、マクロは本文から丸ごと抜け落ちる。目次があるページを markdown で読んでも目次は現れないため、「消えた」と誤認する。マクロの有無を確かめるときは必ず `contentFormat: html` で取得する。

## 書き込む直前に html で本文を取得し、それだけを土台にする

`updateConfluencePage` は本文を丸ごと差し替える。渡した html に無いものはすべて消えるため、前回自分が書いた内容をそのまま送り直すと、その間に他の人がエディタで加えた変更が失われる。

書き込みの直前に必ず `getConfluencePage` を `contentFormat: html` で呼び、その応答の本文だけを土台にして、変更したい見出しの中身だけを差し替える。手元に残した古いコピーや、数分前に取得した本文を土台にしてはならない。人がエディタで保存すると本文中の要素の内部 ID (`data-local-id`) が振り直されるため、古い ID を持つ要素を送るとその要素 (目次マクロなど) が捨てられることがある。

取得を利用者に止められた場合は、書き込みも止める。利用者から「書いてくれ」と言われても、取得し直さずに書くことは許されない。この手順を省いた結果、目次マクロと表の中身を消して利用者に復旧させたことがある。

特に、目次のように API から入れられない要素は人がエディタで足すしかなく、上書きしても自分では戻せない。一度消すと相手に再作業を強いることになる。

## 更新したら必ず html で取得して確認する

更新の呼び出しがバージョン番号を返しても、本文が意図どおりに解釈された保証はない。上に挙げた失敗はいずれも呼び出し自体は成功を返し、ページだけが壊れていた。

更新の直後に `getConfluencePage` を `contentFormat: html` で呼び、書き込み前の本文と比べて、`data-extension-key="toc"` を持つ div の数と `<table` の数が一致していることを確かめる。一致しなければ、利用者に報告するより先にその場で復元する。`contentFormat: markdown` はマクロを表示しないので、この確認の代わりにならない。

構造が入っているかは markdown でも見られる。見出しが `#` に、表が `|` の行に変換されていれば正しい。段落タグに全文が包まれていたり、JSON がそのまま見えていたら失敗である。

なお、応答に含まれる `summary` はキャッシュされた検索用の要約であり、直前の更新を反映していないことがある。確認は必ず `body` を見て行う。

## 更新の呼び出し回数が期待より多ければ、間に他人の編集がある

更新の応答にはバージョン番号が入る。自分が最後に書いたバージョンの次の番号でなければ、その間に誰かが編集している。その場合は自分の書き込みが相手の編集を消した可能性が高いので、直ちに html で取得し直して差分を確かめ、消えた内容を復元する。
