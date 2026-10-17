#!/usr/bin/env -S deno run --allow-env --allow-read --allow-write

const homedir = Deno.env.get("HOME")!;
const VAULT = Deno.env.get("OBSIDIAN_VAULT") ?? `${homedir}/workspace/obsidian`;

const stdin = await new Response(Deno.stdin.readable).text();
let payload: { session_id?: string; transcript_path?: string } = {};
try { payload = JSON.parse(stdin); } catch { /* tolerate empty */ }

const taskId = Deno.env.get("TASK_ID");
if (!taskId) Deno.exit(0);

// Obsidian の vault が無い端末では、セッションの終わりに記録する先が無いので何もしない。
try {
  await Deno.stat(VAULT);
} catch (e) {
  if (e instanceof Deno.errors.NotFound) Deno.exit(0);
  throw e;
}

// frontmatter の読み書きは vault の中のスクリプトと同じ実装を使うため、vault の場所から絶対パスで読み込む。
const { parse, serialize } = await import(`file://${VAULT}/scripts/lib/frontmatter.ts`);

const taskPath = `${VAULT}/Tasks/${taskId}.md`;
let raw: string;
try { raw = await Deno.readTextFile(taskPath); }
catch { Deno.exit(0); }

const transcriptPath = payload.transcript_path;
let lastAssistant = "";
if (transcriptPath) {
  try {
    const txt = await Deno.readTextFile(transcriptPath);
    for (const line of txt.split("\n").reverse()) {
      if (!line) continue;
      try {
        const obj = JSON.parse(line);
        if (obj.type === "assistant") {
          const c = obj.message?.content;
          if (typeof c === "string") { lastAssistant = c; break; }
          if (Array.isArray(c)) {
            const t = c.filter((x: any) => x.type === "text").map((x: any) => x.text).join("\n");
            if (t) { lastAssistant = t; break; }
          }
        }
      } catch { /* skip */ }
    }
  } catch { /* skip */ }
}

const oneLine = lastAssistant.replace(/\s+/g, " ").trim();
const summary = oneLine.length > 240 ? oneLine.slice(0, 240) + "…" : oneLine;
const isDone = /(完了|終わりました|done|実装完了|✅\s*完了)\s*[.。!！]?\s*$/i.test(oneLine.slice(-80));

const now = new Date();
const pad = (n: number) => String(n).padStart(2, "0");
const date = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
const hhmm = `${pad(now.getHours())}:${pad(now.getMinutes())}`;

// Update task file: progress log append (and status update if done)
let parsed: { fm: ReturnType<typeof parse>["fm"]; body: string };
try { parsed = parse(raw); }
catch (e) {
  const msg = e instanceof Error ? e.message : String(e);
  console.error(`Task file ${taskPath} has invalid frontmatter: ${msg}`);
  Deno.exit(1);
}
const { fm, body } = parsed!;
// Append to # 進捗ログ section: find that heading and inject a new line right after it.
// Stop at the next # heading (# 振り返り) or end of body.
const progressLogRe = /(# 進捗ログ\n)([\s\S]*?)(\n# |\s*$)/;
let updatedBody: string;
const m = body.match(progressLogRe);
if (m) {
  const [_full, heading, existing, next] = m;
  const sep = existing.trimEnd().length ? "\n" : "";
  updatedBody = body.replace(progressLogRe, `${heading}${existing}${sep}[${hhmm}] ${summary || "(no summary)"}\n${next}`);
} else {
  // No # 進捗ログ — fail loudly to surface the malformed task file rather than silently dropping the log
  console.error(`Task file has no "# 進捗ログ" section: ${taskPath}`);
  Deno.exit(1);
}

if (isDone) fm.status = "done";
await Deno.writeTextFile(taskPath, serialize(fm, updatedBody));

// Daily note update with inline mkdir-lock (hook is standalone, doesn't import scripts/lib/lock.ts to avoid coupling)
// Inline mkdir-lock (duplicates ~/workspace/obsidian/scripts/lib/lock.ts to avoid cross-repo import).
// If you change the lock naming protocol here, update lock.ts to match (and vice versa).
const lockDir = `${VAULT}/.locks/daily-${date}.lock`;
const deadline = Date.now() + 5000;
let locked = false;
while (Date.now() < deadline) {
  try { await Deno.mkdir(lockDir); locked = true; break; }
  catch { await new Promise((r) => setTimeout(r, 50)); }
}
if (!locked) {
  console.error(`Could not acquire daily lock; daily note not updated for ${taskId}`);
  Deno.exit(0); // exit 0: task file was already updated, don't fail the hook
}
try {
  const dPath = `${VAULT}/Daily/${date}.md`;
  let d = "";
  try { d = await Deno.readTextFile(dPath); } catch { /* no daily yet */ }
  if (d) {
    // Append to ## 進捗ログ section (similar logic to above)
    const dailyProgressRe = /(## 進捗ログ\n)([\s\S]*?)(?=\n## |$)/;
    const dm = d.match(dailyProgressRe);
    if (dm) {
      const [_full, heading, existing] = dm;
      const sep = existing.trimEnd().length ? "\n" : "";
      d = d.replace(dailyProgressRe, `${heading}${existing}${sep}[${hhmm}] ${taskId}: ${summary || "(no summary)"}\n`);
    } else {
      console.error(`Daily note ${dPath} has no "## 進捗ログ" section; skipping progress append`);
    }
    // Toggle checkbox to [x] if done
    if (isDone) {
      const esc = taskId.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      const re = new RegExp(`- \\[ \\] \\[\\[${esc}\\]\\]`);
      d = d.replace(re, `- [x] [[${taskId}]]`);
    }
    await Deno.writeTextFile(dPath, d);
  }
} finally {
  try { await Deno.remove(lockDir, { recursive: true }); } catch { /* ignore */ }
}
