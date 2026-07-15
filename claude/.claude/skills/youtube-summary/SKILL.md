---
name: youtube-summary
description: "Summarize a YouTube video via Gemini's native video input — captures spoken claims, demo footage, and on-screen data, not just the title/description. Invoke with /youtube-summary <url> [focus topic]."
user-invocable: true
disable-model-invocation: true
argument-hint: "<youtube_url> [focus topic]"
---

# YouTube Summary

Gemini watches the video natively (`file_data.file_uri`), so the digest includes things a transcript scrape misses: demos, on-screen numbers, speaker tone.

## Run

```bash
python3 <scripts>/gemini_video.py summarize "<youtube_url>" [--query=<focus topic>]
```

- `<scripts>` = `<this SKILL.md's parent directory>/../web-research/scripts` — shared with web-research (single source of truth for the Gemini client)
- If the arguments contain anything besides the URL, treat it as a focus topic and pass it via `--query=` so the summary prioritizes that angle
- Multiple URLs → run one call per URL concurrently in a single Bash call (`&` + `wait`)

## Present

Relay the returned `summary` as-is under a `## 요약 — <video title or URL>` header. It is already an exhaustive Korean digest — its length is intentional, so do not compress it into a few sentences. You may add a short 핵심 요점 bullet list (3-5 items) on top for scanning.

## Errors

The script prints `{"error": ...}` on failure — relay the message. Common causes: non-YouTube URL (only YouTube is supported natively), private/deleted video, missing `GEMINI_API_KEY`, Gemini quota.
