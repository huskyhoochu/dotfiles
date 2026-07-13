#!/usr/bin/env python3
"""Gemini API client for native YouTube video analysis.

Usage: python3 scripts/gemini_video.py <command> [args...]

Commands:
  summarize <youtube_url> [--query=topic] [--model=gemini-2.5-flash] [--timeout=240]
"""

import json
import os
import re
import sys
import urllib.error
import urllib.request
from typing import NoReturn

BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

YOUTUBE_URL_RE = re.compile(
    r"^https?://(www\.|m\.)?(youtube\.com/(watch\?|shorts/|live/)|youtu\.be/)"
)

SUMMARY_PROMPT = """\
Analyze the content of this video and write the summary in Korean. It will be used \
as source material in a research pipeline.

Include:
1. Core claims/conclusions (what the video is arguing)
2. Concrete data and facts presented as evidence (numbers, demo results, quotes)
3. The speaker's stance and assessment (positive/negative/neutral, and why)
4. Information only available from the video itself (demo footage, interview remarks — \
things a text article would not contain)

Do not invent content that is not in the video. Exclude ad/sponsor segments."""


def get_api_key():
    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        error_exit("GEMINI_API_KEY environment variable not set")
    return key


def error_exit(msg) -> NoReturn:
    json.dump({"error": msg}, sys.stdout)
    print()
    sys.exit(1)


def parse_args(args):
    """Parse --key=value and --flag style arguments."""
    opts = {}
    positional = []
    for arg in args:
        if arg.startswith("--"):
            if "=" in arg:
                k, v = arg[2:].split("=", 1)
                opts[k] = v
            else:
                opts[arg[2:]] = True
        else:
            positional.append(arg)
    return positional, opts


def cmd_summarize(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit(
            "Usage: summarize <youtube_url> [--query=topic] "
            "[--model=gemini-2.5-flash] [--timeout=240]"
        )
    url = positional[0]
    if not YOUTUBE_URL_RE.match(url):
        error_exit(f"Not a YouTube URL (only YouTube is supported natively): {url}")

    model = opts.get("model", "gemini-2.5-flash")
    timeout = int(opts.get("timeout", "240"))

    prompt = SUMMARY_PROMPT
    if "query" in opts:
        prompt += (
            f"\n\nResearch topic: \"{opts['query']}\" — "
            "prioritize content relevant to this topic."
        )

    body = {
        "contents": [
            {
                "parts": [
                    {"file_data": {"file_uri": url}},
                    {"text": prompt},
                ]
            }
        ]
    }
    req = urllib.request.Request(
        f"{BASE_URL}/models/{model}:generateContent",
        data=json.dumps(body).encode(),
        headers={
            "x-goog-api-key": get_api_key(),
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        try:
            detail = json.loads(detail)
        except json.JSONDecodeError:
            pass
        error_exit({"status": e.code, "detail": detail})
    except (urllib.error.URLError, TimeoutError) as e:
        error_exit(f"Request failed: {e}")

    try:
        summary = data["candidates"][0]["content"]["parts"][0]["text"]
    except (KeyError, IndexError):
        error_exit({"unexpected_response": data})

    json.dump(
        {"url": url, "model": model, "summary": summary},
        sys.stdout,
        ensure_ascii=False,
        indent=2,
    )
    print()


COMMANDS = {
    "summarize": cmd_summarize,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        error_exit(f"Unknown command: {cmd}. Available: {', '.join(COMMANDS)}")
    COMMANDS[cmd](sys.argv[2:])
