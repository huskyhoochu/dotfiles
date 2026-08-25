#!/usr/bin/env python3
"""Gemini native YouTube video analysis, called via OpenRouter.

YouTube URL input only works with Gemini served by Google AI Studio, so the
request pins the provider to google-ai-studio (Vertex AI accepts base64 only).

Usage: python3 scripts/gemini_video.py <command> [args...]

Commands:
  summarize <youtube_url> [--query=topic] [--model=google/gemini-2.5-flash] [--timeout=240]
"""

import re
import sys

from _http import api_post, dump, error_exit, get_api_key, parse_args, run_cli

API_URL = "https://openrouter.ai/api/v1/chat/completions"

YOUTUBE_URL_RE = re.compile(
    r"^https?://(www\.|m\.)?(youtube\.com/(watch\?|shorts/|live/)|youtu\.be/)"
)

SUMMARY_PROMPT = """\
Analyze the content of this video and write a thorough digest in Korean. It will be \
used as source material in a research pipeline, replacing the need to watch the video \
— so err on the side of exhaustive, not brief. Length must scale with the video's \
information density: a 10-minute talk or news segment merits 800+ words; never \
compress a substantive video into a few headline sentences.

Cover:
1. Core claims/conclusions (what the video is arguing), following the video's own \
narrative flow — how the argument builds, not just its endpoints
2. EVERY concrete datum presented: numbers, dates, names, benchmarks, demo results. \
Quote notable remarks verbatim (with speaker attribution)
3. The speaker's stance and assessment (positive/negative/neutral, and why), including \
hedges, caveats, and open questions they raise
4. Information only available from the video itself: demo footage, on-screen data, \
interview remarks, visuals — things a text article would not contain

Do not invent content that is not in the video. Exclude ad/sponsor segments."""


def cmd_summarize(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit(
            "Usage: summarize <youtube_url> [--query=topic] "
            "[--model=google/gemini-2.5-flash] [--timeout=240]"
        )
    url = positional[0]
    if not YOUTUBE_URL_RE.match(url):
        error_exit(f"Not a YouTube URL (only YouTube is supported natively): {url}")

    model = opts.get("model", "google/gemini-2.5-flash")
    timeout = int(opts.get("timeout", "240"))

    prompt = SUMMARY_PROMPT
    if "query" in opts:
        prompt += (
            f"\n\nResearch topic: \"{opts['query']}\" — "
            "prioritize content relevant to this topic."
        )

    body = {
        "model": model,
        "provider": {"only": ["google-ai-studio"]},
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "video_url", "video_url": {"url": url}},
                    {"type": "text", "text": prompt},
                ],
            }
        ],
    }
    headers = {"Authorization": f"Bearer {get_api_key('OPENROUTER_API_KEY')}"}
    data = api_post(API_URL, headers, body, timeout=timeout)

    try:
        summary = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        error_exit({"unexpected_response": data})

    dump({"url": url, "model": model, "summary": summary})


COMMANDS = {
    "summarize": cmd_summarize,
}

if __name__ == "__main__":
    run_cli(__doc__, COMMANDS, sys.argv)
