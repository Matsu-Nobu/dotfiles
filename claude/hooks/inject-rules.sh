#!/bin/bash
# PreToolUse フックとして呼ばれ、編集対象のファイル種別に応じた ~/.claude/rules/*.md を additionalContext として注入する。
# 同じルールを同一セッションで二度注入しないよう、注入済みのルール名をセッション ID ごとの一時ファイルに記録する。
set -u

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')

[ -n "$file" ] || exit 0

rules_dir="$HOME/.claude/rules"
case "$file" in
  *.md|*.mdx|*.txt) rules="writing-format vocabulary" ;;
  */spec/*|*/test/*|*_spec.*|*_test.*|*.test.*|*.spec.*) rules="code-comments implementation testing vocabulary" ;;
  *) rules="code-comments implementation vocabulary" ;;
esac

state="${TMPDIR:-/tmp}/claude-injected-rules-${session}"
body=""
for rule in $rules; do
  grep -qx -- "$rule" "$state" 2>/dev/null && continue
  [ -f "$rules_dir/$rule.md" ] || continue
  body="${body}
$(cat "$rules_dir/$rule.md")
"
  printf '%s\n' "$rule" >> "$state"
done

[ -n "$body" ] || exit 0

context="このファイルを編集する前に、以下のルールを必ず適用すること。
$body"

jq -n --arg ctx "$context" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
