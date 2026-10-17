---
description: End-of-day summary, tomorrow's TODO, and reflection
---

You are running `/eod` to wrap up the workday for the user. Operate from `~/workspace/obsidian` (the vault).

# Inputs to gather (parallel where possible)

1. **Today's tasks**: List files in `~/workspace/obsidian/Tasks/*.md` that match ANY of:
   - frontmatter `created:` equals today (`date +%Y-%m-%d`),
   - frontmatter `status` is `doing` (regardless of mtime),
   - frontmatter `status` is `done` and the file was modified today (mtime == today).
   Deduplicate. Parse frontmatter and content (especially `# 進捗ログ`).

   If no tasks match (empty task set), proceed normally — all non-excluded repos will then appear under Untracked work, and the "完了した/進行中/未着手" sub-sections will all read "なし".
2. **Per-task repos**: From those files, collect the set of `repo:` values.
3. **git log per repo**: For each repo in the set, run:
   `git -C ~/workspace/<repo> log --all --since=midnight --author="$(git -C ~/workspace/<repo> config user.email)" --pretty=format:'%h %s'`
4. **Claude Code logs per repo**: For each repo in the set, read `.jsonl` files under `~/.claude/projects/-Users-*-workspace-<repo>/` with mtime today. Treat each `.jsonl` as one session. For each, extract the first user message (session intent) and the final assistant message; produce a 1-2 line summary per session.
5. **Slack posts**: Use the `mcp__plugin_slack_slack__*` tools to fetch the user's own messages in public channels since midnight (DM excluded). If MCP not authenticated, note "Slack: skipped — run `mcp__plugin_slack_slack__authenticate`" and continue.
6. **Untracked-work check**: Read `~/workspace/obsidian/.workrc.yaml` for `exclude_repos`. For each `~/workspace/*` repo NOT in that exclude list AND NOT in the task-repo set, run the same `git log` command. Any output is "Untracked work" (flag it).

# Output to daily note

Write the following into the `## 退勤時サマリ` section of `~/workspace/obsidian/Daily/<today>.md`:
- If `Daily/<today>.md` does not exist, create it from `~/workspace/obsidian/templates/daily.md` (replacing `{{DATE}}` and `{{WEEKDAY}}`) first.
- If the `## 退勤時サマリ` section is missing in the file, append the section (header + body) at the end of the file.
- If the section already exists, replace its content (everything between the header and the next `## ` or EOF) with the generated body.

```
### 完了したタスク
- [[<task-id>]] <title>: <one-line outcome from progress log>

### 進行中のタスク
- [[<task-id>]] <title>: <current state, blockers if any>

### 未着手で残ったタスク
- [[<task-id>]] <title>

### Untracked work (⚠️ タスク非紐付け)
- <repo>: <N commits>: <commit subjects>

### Slack上で出てきた論点
- <channel>: <summary of own post>

### その他 (CC内対話で出た重要な決定・気付き)
- ...
```

If a section has no content, write the section header + "なし". Do not omit sections.

# Tomorrow's TODO (interactive)

Walk the user through these questions, one at a time:

1. "未完了タスク (進行中 + 未着手) のうち、明日に持ち越すものはどれですか？ 番号で答えてください."
2. "明日新たに追加したいタスクはありますか？ (タイトルと対象repo を1つずつ)"

For each chosen task:
- Generate a slug from the title (lowercase, kebab-case, max 40 chars).
- Create `~/workspace/obsidian/Tasks/<tomorrow>-<slug>.md` from the template (stub: frontmatter filled, `# 計画` body empty).
- Add `- [ ] [[<tomorrow>-<slug>]] <title>` to `Daily/<tomorrow>.md` under `## 今日のTODO` (create the file from `templates/daily.md` if absent).

Prefer using `~/bin/task new "<title>" --repo=<repo>` if `<tomorrow>` is today. Otherwise create files directly with the templates (since `task new` always uses today's date).

# Reflection (skippable)

Ask:
- "今日の学び・気付き・所感はありますか？ (Enterのみでスキップ)"

If input given, ask classification (one question):
- "次のどれに分類しますか? 1: 特定タスクに紐づく / 2: 汎用ナレッジ (トピック指定) / 3: 雑記"

Write to the appropriate file:
- **1**: ask which task (offer the today's list); append the reflection to that task file's `# 振り返り` section.
- **2**: ask the topic name; append to `~/workspace/obsidian/Reflections/Knowledge/<topic>.md` (create with `---\ntags: [<topic>]\n---\n\n` if absent).
- **3 (雑記)**: Append to `~/workspace/obsidian/Reflections/Daily/<today>.md` (create with `# <today> 雑記\n` if absent). ALSO append to the `## 振り返り` section of the today's daily note. If the daily note has no `## 振り返り` section, append one at the end of the file.

When everything is written, output: "退勤処理完了。お疲れ様でした."
