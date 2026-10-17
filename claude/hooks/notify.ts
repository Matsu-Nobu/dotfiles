#!/usr/bin/env -S deno run --allow-run=ps,tee --allow-read
// Claude Code の hook として、応答の終了・許可待ち・入力待ちを、セッションの名前を付けて通知する。
// 通知は OSC 777 の制御文字列として Claude Code の端末に書き込み、WezTerm が OS の通知として表示する。
// Claude Code のタブを見ているときに通知を出さない判定は、WezTerm の notification_handling が行う。

interface HookData {
  hook_event_name: "Stop" | "Notification" | "PermissionRequest"
  transcript_path: string
  cwd: string
  notification_type?: string
  tool_name?: string
}

const messageFor = (data: HookData): string | null => {
  switch (data.hook_event_name) {
    case "Stop":
      return "応答が終わりました"
    case "PermissionRequest":
      return `許可を待っています（${data.tool_name}）`
    case "Notification":
      // 許可待ちは PermissionRequest でツール名付きの通知を出すので、ここでは出さない。
      if (data.notification_type === "idle_prompt" || data.notification_type === "elicitation_dialog") {
        return "入力を待っています"
      }
      return null
  }
}

// 会話記録の書式は公開された仕様ではないため、名前が読めなければディレクトリ名を使う。
const sessionName = async (data: HookData): Promise<string> => {
  let custom = ""
  let generated = ""
  try {
    const text = await Deno.readTextFile(data.transcript_path)
    for (const line of text.split("\n")) {
      if (line.includes('"type":"custom-title"')) custom = JSON.parse(line).customTitle ?? custom
      else if (line.includes('"type":"ai-title"')) generated = JSON.parse(line).aiTitle ?? generated
    }
  } catch (error) {
    console.error(`notify.ts: 会話記録からセッションの名前を読めませんでした: ${error}`)
  }
  return custom || generated || data.cwd.split("/").pop() || "Claude Code"
}

// hook のプロセスは端末を持たないので、親プロセスをたどって Claude Code の端末を探す。
const findTerminal = async (): Promise<string | null> => {
  let pid = Deno.pid
  for (let depth = 0; depth < 10 && pid > 1; depth++) {
    const out = await new Deno.Command("ps", { args: ["-o", "ppid=,tty=", "-p", String(pid)] }).output()
    const [ppid, tty] = new TextDecoder().decode(out.stdout).trim().split(/\s+/)
    if (tty && tty !== "??" && tty !== "?") return `/dev/${tty}`
    pid = Number(ppid)
  }
  return null
}

// OSC 777 はセミコロンで項目を区切るので、文字列の中のセミコロンと制御文字を取り除く。
const sanitize = (s: string): string => s.replace(/[;\x00-\x1f\x7f]/g, " ")

const data: HookData = JSON.parse(await new Response(Deno.stdin.readable).text())
const message = messageFor(data)
if (message) {
  const terminal = await findTerminal()
  if (terminal) {
    const title = sanitize(await sessionName(data))
    // Deno は端末のような特殊なファイルへの書き込みにすべての権限を要求するので、書き込みは tee に任せる。
    const tee = new Deno.Command("tee", { args: ["-a", terminal], stdin: "piped", stdout: "null" }).spawn()
    const writer = tee.stdin.getWriter()
    await writer.write(new TextEncoder().encode(`\x1b]777;notify;${title};${sanitize(message)}\x1b\\`))
    await writer.close()
    await tee.status
  } else {
    console.error("notify.ts: Claude Code の端末が見つからないため通知を送りませんでした")
  }
}
