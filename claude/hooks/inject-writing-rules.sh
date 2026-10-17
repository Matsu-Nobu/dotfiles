#!/bin/bash
# PreToolUse フックとして呼ばれ、Jira・Confluence・GitHub の PR に文章を書き込むツールの直前に、
# ~/.claude/rules/ の writing-format.md・vocabulary.md・reader-check.md を渡す。
# ツールを呼び出した時点では本文がもうできているので、セッションで最初の書き込みだけは止めて、規則に沿って書き直させる。
# 2 回目以降の書き込みは止めず、規則を additionalContext として渡すだけにする。
set -u

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"')
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""')
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

case "$tool" in
  *createJiraIssue|*editJiraIssue|*addCommentToJiraIssue) ;;
  *createConfluencePage|*updateConfluencePage|*createConfluenceFooterComment|*createConfluenceInlineComment) ;;
  *create_pull_request|*create_pull_request_review|*add_issue_comment|*update_issue) ;;
  Bash)
    # gh で PR の説明・コメント・レビューを書き込むコマンドだけを対象にする。
    printf '%s' "$command" | grep -Eq 'gh (pr (create|edit|comment|review)|issue (create|edit|comment))|gh api .*(comments|reviews)' || exit 0
    ;;
  *) exit 0 ;;
esac

rules_dir="$HOME/.claude/rules"
body=""
for rule in writing-format vocabulary reader-check; do
  [ -f "$rules_dir/$rule.md" ] || continue
  body="${body}
$(cat "$rules_dir/$rule.md")
"
done
[ -n "$body" ] || exit 0

state="${TMPDIR:-/tmp}/claude-writing-rules-${session}"
if [ ! -f "$state" ]; then
  : > "$state"
  reason="この書き込みは、文章の規則を読む前に書かれている。以下の規則に沿って本文を書き直し、reader-check.md の手順でサブエージェントに読ませて指摘を直してから、もう一度呼び出すこと。
$body"
  jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
fi

context="この書き込みの本文が、以下の規則に沿っていて、reader-check.md の確認を通したものであることを確かめてから実行すること。
$body"
jq -n --arg ctx "$context" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
