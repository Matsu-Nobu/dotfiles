#!/usr/bin/env -S deno run --allow-read --allow-env

// Constants
const COMPACTION_THRESHOLD = 200000 // Opus 4.5

// Helper function to format token count
function formatTokenCount(tokens: number): string {
  if (tokens >= 1000000) {
    return `${(tokens / 1000000).toFixed(1)}M`
  } else if (tokens >= 1000) {
    return `${(tokens / 1000).toFixed(1)}K`
  }
  return tokens.toString()
}

// Function to calculate tokens from transcript
async function calculateTokensFromTranscript(filePath: string): Promise<number> {
  try {
    const content = await Deno.readTextFile(filePath)
    const lines = content.trim().split("\n")

    let lastUsage = null

    for (const line of lines) {
      try {
        const entry = JSON.parse(line)

        // Check if this is an assistant message with usage data
        if (entry.type === "assistant" && entry.message?.usage) {
          lastUsage = entry.message.usage
        }
      } catch {
        // Skip invalid JSON lines
      }
    }

    if (lastUsage) {
      // The last usage entry contains cumulative tokens
      const totalTokens =
        (lastUsage.input_tokens || 0) +
        (lastUsage.output_tokens || 0) +
        (lastUsage.cache_creation_input_tokens || 0) +
        (lastUsage.cache_read_input_tokens || 0)
      return totalTokens
    }

    return 0
  } catch {
    return 0
  }
}

// Read JSON input from stdin
const decoder = new TextDecoder()
const input = decoder.decode(
  await Deno.stdin.readable
    .getReader()
    .read()
    .then((r) => r.value),
)
const data = JSON.parse(input)

// Extract values
const sessionId = data.session_id
const transcriptPath = data.transcript_path

// Calculate token usage for current session
let totalTokens = 0

// Try to get tokens from transcript file
if (transcriptPath) {
  try {
    const stat = await Deno.stat(transcriptPath)
    if (stat.isFile) {
      totalTokens = await calculateTokensFromTranscript(transcriptPath)
    }
  } catch {
    // Transcript file doesn't exist or can't be read
  }
} else if (sessionId) {
  // Fallback: Find transcript file for the current session
  const projectsDir = `${Deno.env.get("HOME")}/.claude/projects`

  try {
    for await (const entry of Deno.readDir(projectsDir)) {
      if (entry.isDirectory) {
        const transcriptFile = `${projectsDir}/${entry.name}/${sessionId}.jsonl`

        try {
          const stat = await Deno.stat(transcriptFile)
          if (stat.isFile) {
            totalTokens = await calculateTokensFromTranscript(transcriptFile)
            break
          }
        } catch {
          // File doesn't exist in this project, continue
        }
      }
    }
  } catch {
    // Projects directory doesn't exist or other error
  }
}

// Helper function to format seconds into "Xh Ym" or "Ym" string
function formatResetTime(epochSeconds: number): string {
  const now = Math.floor(Date.now() / 1000)
  const diffSeconds = epochSeconds - now
  if (diffSeconds <= 0) return "now"
  const hours = Math.floor(diffSeconds / 3600)
  const minutes = Math.floor((diffSeconds % 3600) / 60)
  if (hours > 0) {
    return `${hours}h${minutes}m`
  }
  return `${minutes}m`
}

// Build rate limit display string
function buildRateLimitDisplay(data: Record<string, unknown>): string {
  const rateLimits = data.rate_limits as Record<string, { used_percentage: number; resets_at: number }> | undefined
  if (!rateLimits) return ""

  const parts: string[] = []

  const fiveHour = rateLimits.five_hour
  if (fiveHour != null) {
    const pct = Math.round(fiveHour.used_percentage)
    const resetStr = formatResetTime(fiveHour.resets_at)
    parts.push(`limit: ${pct}% (reset in ${resetStr})`)
  }

  const sevenDay = rateLimits.seven_day
  if (sevenDay != null) {
    const pct = Math.round(sevenDay.used_percentage)
    parts.push(`weekly: ${pct}%`)
  }

  return parts.join(" | ")
}

// Output
const rateLimitDisplay = buildRateLimitDisplay(data)
const modelName: string | undefined = data.model?.display_name

const tokenPart = (() => {
  if (totalTokens === 0) return "🟢 0 (0%)"

  const tokenDisplay = formatTokenCount(totalTokens)
  const percentage = Math.min(100, Math.round((totalTokens / COMPACTION_THRESHOLD) * 100))

  const { color, emoji } = (() => {
    if (percentage >= 90) {
      return { color: "\x1b[31m", emoji: "🔴" }
    }
    if (percentage >= 70) {
      return { color: "\x1b[33m", emoji: "🟡" }
    }
    return { color: "\x1b[32m", emoji: "🟢" }
  })()

  return `${emoji} ${tokenDisplay} (${color}${percentage}%\x1b[0m)`
})()

const parts = [modelName ? `\x1b[36m${modelName}\x1b[0m` : "", tokenPart, rateLimitDisplay].filter((part) => part !== "")
console.log(parts.join(" | "))
