#!/usr/bin/env python3
"""Stop hook: when the assistant's last turn is written mostly in English prose, block the stop and
ask for the same content again in Korean. Code blocks, inline code, URLs and paths are not counted."""
import json
import os
import re
import sys
import time

LOG = os.path.expanduser("~/.claude/hooks/korean-only.log")


def turn_texts(path):
    """The text the assistant wrote since the user's last prompt, oldest first, and whether the
    transcript already ends on the assistant's words."""
    with open(path, encoding="utf-8") as transcript:
        entries = [json.loads(line) for line in transcript if line.strip()]
    texts = []
    last_kind = None
    for entry in reversed(entries):
        message = entry.get("message") or {}
        content = message.get("content")
        if entry.get("type") == "user":
            # A tool result belongs to the turn; a prompt starts it.
            if isinstance(content, list) and all(block.get("type") == "tool_result" for block in content):
                last_kind = last_kind or "tool"
                continue
            break
        if entry.get("type") == "assistant" and isinstance(content, list):
            words = [block.get("text", "") for block in content if block.get("type") == "text"]
            if words:
                last_kind = last_kind or "text"
            texts.extend(reversed(words))
    return list(reversed(texts)), last_kind == "text"


payload = json.load(sys.stdin)
with open(LOG, "w", encoding="utf-8") as log:
    log.write(json.dumps(sorted(payload.keys())) + "\n")
if payload.get("stop_hook_active"):
    sys.exit(0)

# The stop can come before the final words reach the transcript: wait for them briefly.
for _ in range(10):
    texts, ends_on_text = turn_texts(payload["transcript_path"])
    if ends_on_text:
        break
    time.sleep(0.2)
last = payload.get("last_assistant_message")
if isinstance(last, str) and last.strip() and last not in texts:
    texts.append(last)

def english(text):
    """Whether a block of text is English prose: code, inline code, URLs and paths left out, Latin
    letters outweighing Hangul syllables twice over (a syllable is about two letters of text)."""
    prose = re.sub(r"```.*?```", " ", text, flags=re.S)
    prose = re.sub(r"`[^`]*`", " ", prose)
    prose = re.sub(r"https?://\S+|\S*/\S*", " ", prose)
    hangul = len(re.findall(r"[\uac00-\ud7a3]", prose))
    latin = len(re.findall(r"[A-Za-z]", prose))
    return latin > 40 and latin > 2 * hangul


# Each block is judged on its own: a long Korean block does not cover an English one beside it.
if any(english(text) for text in texts):
    print(json.dumps({
        "decision": "block",
        "reason": "방금 응답의 일부가 영어로 쓰였다. 같은 내용을 한국어로 다시 써라. 코드 식별자와 명령만 원문으로 둔다.",
    }, ensure_ascii=False))
