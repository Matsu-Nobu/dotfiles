#!/bin/bash
# rails / rake の db: タスクが開発用データベースを壊すのを止める。
# RAILS_ENV を省くとコンテナの既定 (development) が対象になり、
# db:test:prepare でも development が purge されて空になる。
cmd=$(cat | jq -r '.tool_input.command // ""')

# rails / rake に続くタスク名だけを見る。grep の引数に現れた文字列は対象にしない。
task=$(printf '%s' "$cmd" | grep -oE '(rails|rake)[[:space:]]+"?db:[a-z_:]+' | head -1 | grep -oE 'db:[a-z_:]+')
[ -z "$task" ] && exit 0

deny() {
  jq -cn --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

case "$task" in
  db:reset|db:drop|db:setup|db:schema:load)
    deny "$task はデータベースを作り直すため禁止しています。テスト用のスキーマを更新したいなら db:test:prepare を -e RAILS_ENV=test 付きで実行してください。" ;;
  db:test:*)
    printf '%s' "$cmd" | grep -qE 'RAILS_ENV=test' ||
      deny "$task は RAILS_ENV=test を明示しないと development のデータベースが対象になり、中身が消えます。docker compose exec -T -e RAILS_ENV=test puma bundle exec rails $task の形にしてください。" ;;
  *)
    printf '%s' "$cmd" | grep -qE 'RAILS_ENV=(test|development)' ||
      deny "$task はどちらのデータベースが対象か分かるよう RAILS_ENV を明示してください。開発用なら -e RAILS_ENV=development、テスト用なら -e RAILS_ENV=test を付けます。" ;;
esac

exit 0
