#!/usr/bin/env bash
# ツールの結果を受け取るたびに、次に書く文章を日本語で書くことを思い出させる 1 行を添える。
# Claude はコードやログを読んだ直後に英語で書き始めやすく、 英語で書いてから差し戻すとトークンを無駄にする。
# 英語になりやすい時点の直前に規則を置くことで、 書く前に防ぐ。
set -uo pipefail
cat > /dev/null
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"次に利用者へ書く文章は、すべて日本語で書く。英語のままでよいのはコード・コマンド・パス・識別子だけ。"}}'
