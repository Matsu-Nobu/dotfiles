#!/usr/bin/env bash
# 作業を残したまま turn を終えるのを止める。
# 検査は 2 種類ある。
# 一つは 「起動した」 「実行中だ」 と実績や進行を報告しているのに、 その turn に tool call が 1 件も無い場合。
# 報告が事実に反しているので、 利用者は動いていない作業を待つことになる。
# もう一つは、 応答が許可された終わり方のどれでもない場合。
# 止まってよい状態は 3 つしかないので、 その 3 つを列挙して、 それ以外を止める。
# 言い回しを禁止する方式は言い換えで抜けられるため、 許可する終わり方を数える方式にしている。
# 同一の応答に対しては 1 度しか発火しないので、 停止が無限に繰り返されることはない。
set -uo pipefail

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')

[ -z "$transcript" ] || [ ! -f "$transcript" ] && exit 0

# 同じ応答で二度止めないためのマーカーを置く。
# 発火する直前に呼び、 既に発火済みなら黙って抜ける。
already_fired() {
  local marker_dir="${TMPDIR:-/tmp}/claude-continuation-guard"
  mkdir -p "$marker_dir"
  local digest
  digest=$(printf '%s' "$session:$1" | shasum -a 256 | cut -d' ' -f1)
  local marker="$marker_dir/$digest"
  find "$marker_dir" -type f -mtime +1 -delete 2>/dev/null
  [ -f "$marker" ] && return 0
  : > "$marker"
  return 1
}

block() {
  jq -n --arg reason "$1" '{decision: "block", reason: $reason}'
  exit 0
}

# 直近の利用者発言より後の assistant 発言をひとまとまりの turn として取り出す。
# tool_result は利用者発言ではないので区切りに使わない。
turn=$(jq -rs '
  def is_user_turn:
    .type == "user"
    and (
      (.message.content | type) == "string"
      or (
        (.message.content | type) == "array"
        and ((.message.content | map(.type) | index("tool_result")) | not)
      )
    );
  [ .[] | select(.type == "user" or .type == "assistant") ] as $m
  | ($m | map(is_user_turn) | rindex(true)) as $i
  | $m[(($i // -1) + 1):] as $turn
  | {
      text: (
        $turn
        | map(select(.type == "assistant") | .message.content | select(type == "array") | map(select(.type == "text") | .text) | join("\n"))
        | join("\n")
      ),
      last_text: (
        $turn
        | map(select(.type == "assistant") | .message.content | select(type == "array") | map(select(.type == "text") | .text) | join("\n"))
        | map(select(length > 0))
        | last // ""
      ),
      tools: (
        $turn
        | map(select(.type == "assistant") | .message.content | select(type == "array") | map(select(.type == "tool_use")) | length)
        | add // 0
      )
    }
  | @json
' "$transcript" 2>/dev/null)

[ -z "$turn" ] && exit 0

turn_text=$(printf '%s' "$turn" | jq -r '.text // empty')
tool_count=$(printf '%s' "$turn" | jq -r '.tools // 0')

[ -z "$turn_text" ] && exit 0

# フックが走った時点で見えている、 turn の最後のメッセージの本文。 最後の応答が書かれたかどうかの判定に使う。
# 下の final_text と同じく 1 メッセージ単位で取る。
# turn 全体をつないだ本文と比べると、 途中で本文を書いた turn では最初から一致しない。
# その場合、 最後の応答がまだ書かれていないのに途中の本文を最後の応答とみなして止めてしまう。
last_seen_text=$(printf '%s' "$turn" | jq -r '.last_text // empty' | sed -e 's/[[:space:]]*$//')

# tool call を 1 件も出していない turn だけが、 実績報告の検査対象になる。
if [ "$tool_count" -eq 0 ]; then
  # 応答本文に tool call の形をした文字列を書いている。
  # これは呼び出したつもりで地の文を出力しただけなので、 実際には何も実行されていない。
  if printf '%s' "$turn_text" | grep -qE '(Agent|Task|Bash|Read|Write|Edit|Grep|Glob|WebFetch|WebSearch|Workflow|Skill)\(\{'; then
    already_fired "faketool:$turn_text" || block "応答本文に tool call の形をした文字列が含まれていますが、 この turn では tool を 1 件も呼び出していません。 地の文に書いても実行されません。 実行するなら、 いま実際に tool call を出してください。"
  fi

  # 起動済み・進行中と報告しているのに tool call が無い。
  # 利用者は動いていない作業の完了を待つことになる。
  if printf '%s' "$turn_text" | grep -qE '(起動しました|起動した|実行しました|走らせて|動かして|調べさせて|調査させて|検索させて|分析させて|並行で(調|進|走|動)|バックグラウンドで(実行|起動|走)|(実行|調査|作業|処理|分析)中です|進行中です|進めています|待っています)'; then
    already_fired "falseclaim:$turn_text" || block "作業を起動した、 あるいは進行中だと報告していますが、 この turn では tool を 1 件も呼び出していません。 報告が事実に反しており、 利用者は動いていない作業を待つことになります。 実際に起動するなら、 いま tool call を出してください。 起動しないなら、 その報告を撤回して、 なぜ実行しないのかを明示してください。"
  fi
fi

# ここから先は、 応答の終わり方の検査。
# 止まってよいのは次の 3 つの状態だけで、 応答はそれぞれ決まった一文で終える。
#   判断してください。 — 利用者にしか決められないことがあり、 答えを待つ
#   完了しました。     — 依頼された範囲を終えた
#   中断します。       — 終えていないが続けられない。 直前に理由を書く
# 末尾の完全一致で見るので、 同じ語句が文中に現れても通らない。
#
# 最後の応答は、 このフックが走る時点ではまだ transcript に書かれていないことがある。
# 書かれるまで最大 3 秒待ち、 待っても現れなければ検査せずに通す。
# 見えていない本文を根拠に止めると、 正しく終えた応答まで差し戻すことになる。
final_text=""
for _ in $(seq 1 15); do
  final_text=$(jq -rs '
    [ .[] | select(.type == "assistant") | .message.content | select(type == "array") | map(select(.type == "text") | .text) | join("\n") ]
    | map(select(length > 0))
    | last // ""
  ' "$transcript" 2>/dev/null | sed -e 's/[[:space:]]*$//')

  [ -n "$final_text" ] && [ "$final_text" != "$last_seen_text" ] && break
  sleep 0.2
done

# 待っても turn の本文から進んでいないなら、 最後の応答をまだ見られていない。
[ -z "$final_text" ] && exit 0
[ "$final_text" = "$last_seen_text" ] && exit 0

if printf '%s' "$final_text" | grep -qE '(判断してください|完了しました|中断します)[。．\.]$'; then
  exit 0
fi

already_fired "ending:$final_text" || block "応答が、 止まってよい終わり方のどれでもありません。 止まってよいのは次の 3 つだけです。 利用者にしか決められないことを待つなら 「判断してください。」、 依頼された範囲を終えたなら 「完了しました。」、 終えていないが続けられないなら理由を書いたうえで 「中断します。」 で終えてください。 どれにも当てはまらないなら、 まだ作業が残っています。 いま tool call を出して続きを実行してください。"

exit 0
