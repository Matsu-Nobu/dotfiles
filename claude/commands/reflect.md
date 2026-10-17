---
description: Add a reflection note (knowledge or daily) outside of EOD
---

You are running `/reflect`. Use this to record a reflection note any time during the day.

Ask the user, one at a time:

1. "振り返りの内容を教えてください."
2. "次のどれに分類しますか? 1: 現在作業中のタスクに紐づく / 2: 汎用ナレッジ (トピック指定) / 3: 雑記"

If env `$TASK_ID` is set, mention the task name parenthetically next to option 1, e.g. "1: 現在作業中のタスクに紐づく ([[<task-id>]])".

Write to the appropriate file:

- **1**: If `$TASK_ID` is set, append to `~/workspace/obsidian/Tasks/$TASK_ID.md` under `# 振り返り` (substitute `$TASK_ID` into the path before calling Read/Edit; if you use Bash, env expansion works). If `$TASK_ID` is unset, ask which task and append to that one.
- **2**: Ask the topic name; append to `~/workspace/obsidian/Reflections/Knowledge/<topic>.md` (create with `---\ntags: [<topic>]\n---\n\n` if absent).
- **3**: Append to `~/workspace/obsidian/Reflections/Daily/<today>.md` (create with `# <today> 雑記\n` if absent).

When done, output: "振り返りを保存しました."
