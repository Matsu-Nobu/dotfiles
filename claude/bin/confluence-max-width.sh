#!/bin/bash
# 指定した Confluence のページの幅を、エディタの最大の幅に切り替える。
# ページの幅は本文ではなく、ページに付く設定の値 content-appearance-published と content-appearance-draft に保存されている。
# エディタで最大の幅を選んだときの値は "max" である。
# 認証には、macOS のキーチェーンのサービス名 atlassian-api-token の項目に保存した API トークンを使う。
# Confluence のサイトのホスト名は、環境変数 ATLASSIAN_SITE から読む。
# 使い方: ATLASSIAN_SITE=<ホスト名> confluence-max-width.sh <ページの ID> [<ページの ID> ...]
set -euo pipefail

[ "$#" -ge 1 ] || { echo "使い方: $0 <ページの ID> [...]" >&2; exit 2; }
[ -n "${ATLASSIAN_SITE:-}" ] || { echo "環境変数 ATLASSIAN_SITE に Confluence のサイトのホスト名を設定してください" >&2; exit 2; }

base="https://${ATLASSIAN_SITE}/wiki/api/v2"
acct=$(security find-generic-password -s atlassian-api-token | sed -n 's/.*"acct"<blob>="\(.*\)"/\1/p')
token=$(security find-generic-password -s atlassian-api-token -w)

api() {
  curl -sS --fail-with-body -u "$acct:$token" -H "Content-Type: application/json" "$@"
}

for page in "$@"; do
  for key in content-appearance-published content-appearance-draft; do
    current=$(api "$base/pages/$page/properties?key=$key")
    id=$(printf '%s' "$current" | jq -r '.results[0].id // empty')
    if [ -z "$id" ]; then
      api -X POST "$base/pages/$page/properties" -d "$(jq -n --arg k "$key" '{key: $k, value: "max"}')" > /dev/null
    else
      value=$(printf '%s' "$current" | jq -r '.results[0].value')
      if [ "$value" != "max" ]; then
        version=$(printf '%s' "$current" | jq -r '.results[0].version.number')
        api -X PUT "$base/pages/$page/properties/$id" \
          -d "$(jq -n --arg k "$key" --argjson v "$((version + 1))" '{key: $k, value: "max", version: {number: $v}}')" > /dev/null
      fi
    fi
    after=$(api "$base/pages/$page/properties?key=$key" | jq -r '.results[0].value')
    echo "$page $key=$after"
    [ "$after" = "max" ] || { echo "ページ $page の $key が max になっていない" >&2; exit 1; }
  done
done
