#!/bin/bash
# PreToolUse フックとして呼ばれ、Confluence ページの作成・更新ツールが実行される直前に
# ~/.claude/rules/confluence.md を additionalContext として注入する。
# ページの上書き事故を防ぐ規則なので、同一セッションでも呼び出しごとに毎回注入する。
set -u

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')

case "$tool" in
  *updateConfluencePage|*createConfluencePage) ;;
  *) exit 0 ;;
esac

rule="$HOME/.claude/rules/confluence.md"
[ -f "$rule" ] || exit 0

context="Confluence ページを書き込む前に、以下のルールを必ず適用すること。特に、書き込みの直前に contentFormat: html で本文を取得し直していなければ、この呼び出しを中止して先に取得すること。
$(cat "$rule")"

jq -n --arg ctx "$context" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
