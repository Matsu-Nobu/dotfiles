#!/usr/bin/env python3
# Claude が利用者に見せる文章に英語の段落が混ざったら差し戻す。
# 応答を終えるとき（Stop）は、その turn で書いた文章すべてを検査する。
# ツールを呼ぶ前（PreToolUse）は、直前に書いた文章だけを検査する。
# コードブロック・インラインコード・URL・パスは英語のままでよいので、検査の前に取り除く。
# 段落ごとに英字と日本語の文字を数え、英字が多く日本語が少ない段落を英語とみなす。
# 同じ文章に対しては 1 度しか差し戻さないので、差し戻しが繰り返し続くことはない。
import hashlib
import json
import os
import re
import sys
import tempfile
import time

MIN_LATIN = 40
MAX_JAPANESE_RATIO = 0.3
JAPANESE = re.compile(r"[぀-ヿ㐀-䶿一-鿿ｦ-ﾟ]")
LATIN = re.compile(r"[A-Za-z]")


def strip_allowed(text):
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"`[^`\n]*`", " ", text)
    text = re.sub(r"\[[^\]\n]*\]\([^)\n]*\)", " ", text)
    text = re.sub(r"https?://\S+", " ", text)
    text = re.sub(r"(?:~|\.{0,2})?/[\w.\-~/()（）぀-ヿ一-鿿]+", " ", text)
    return text


def english_paragraphs(text):
    found = []
    for para in re.split(r"\n\s*\n", strip_allowed(text)):
        latin = len(LATIN.findall(para))
        japanese = len(JAPANESE.findall(para))
        if latin >= MIN_LATIN and japanese / (japanese + latin) < MAX_JAPANESE_RATIO:
            found.append(para.strip())
    return found


def is_user_turn(entry):
    if entry.get("type") != "user":
        return False
    content = entry.get("message", {}).get("content")
    if isinstance(content, str):
        return True
    if isinstance(content, list):
        return not any(isinstance(b, dict) and b.get("type") == "tool_result" for b in content)
    return False


def turn_texts(path):
    entries = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    start = 0
    for i, e in enumerate(entries):
        if is_user_turn(e):
            start = i + 1
    texts = []
    for e in entries[start:]:
        if e.get("type") != "assistant":
            continue
        content = e.get("message", {}).get("content")
        if isinstance(content, list):
            for b in content:
                if isinstance(b, dict) and b.get("type") == "text" and b.get("text", "").strip():
                    texts.append(b["text"])
    return texts


def already_fired(session, text):
    marker_dir = os.path.join(tempfile.gettempdir(), "claude-language-guard")
    os.makedirs(marker_dir, exist_ok=True)
    now = time.time()
    for name in os.listdir(marker_dir):
        p = os.path.join(marker_dir, name)
        if now - os.path.getmtime(p) > 86400:
            os.remove(p)
    digest = hashlib.sha256(f"{session}:{text}".encode()).hexdigest()
    marker = os.path.join(marker_dir, digest)
    if os.path.exists(marker):
        return True
    open(marker, "w").close()
    return False


def reason(paragraphs):
    quoted = "\n\n".join(p[:400] for p in paragraphs[:3])
    return (
        "英語で書いた段落があります。利用者に見せる文章は、すべて日本語で書いてください。"
        "コード・コマンド・パス・識別子だけは英語のままでかまいません。"
        "次の段落を日本語で書き直してから、続けてください。\n\n" + quoted
    )


def main():
    data = json.load(sys.stdin)
    path = data.get("transcript_path")
    if not path or not os.path.exists(path):
        return
    event = data.get("hook_event_name")
    texts = turn_texts(path)
    if not texts:
        return
    target = texts[-1] if event == "PreToolUse" else "\n\n".join(texts)
    paragraphs = english_paragraphs(target)
    if not paragraphs or already_fired(data.get("session_id", ""), target):
        return
    if event == "PreToolUse":
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
                                                 "permissionDecisionReason": reason(paragraphs)}}, ensure_ascii=False))
    else:
        print(json.dumps({"decision": "block", "reason": reason(paragraphs)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
