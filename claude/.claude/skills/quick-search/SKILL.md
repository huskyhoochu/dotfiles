---
name: quick-search
description: |
  Simple web search and page content extraction using Tavily API. Returns clean,
  organized results without deep analysis or cross-source verification.
  Use when the user needs a quick web search, wants to look something up,
  check recent news, or extract content from a specific URL. Trigger on:
  "검색해줘", "찾아봐", "search for", "look up", "이거 좀 찾아봐",
  "이 페이지 내용 가져와", or any simple information lookup request.
  Also use when the user provides a URL and wants its content extracted.
  For comprehensive multi-source research with cross-verification and
  synthesis, use web-research instead.
user_invocable: true
argument: "<query_or_url> [--news] [--limit=N] [--recency=week]"
---

# Quick Search

Fast web search and page extraction via Tavily API. No subagents, no cross-verification — just clean results.

## Mode Detection

- Argument starts with `http://` or `https://` → **Extract mode**
- Otherwise → **Search mode**

## Search Mode

```bash
python3 <skill_dir>/scripts/tavily_api.py search "<query>" --limit=5
```

**Flags passed through from user arguments:**
- `--news` → add `--news` (switches topic to news)
- `--limit=N` → override default 5
- `--recency=week` → time filter (day, week, month, year)
- `--domains=a.com,b.com` → restrict to specific domains

The script returns JSON with an `answer` field (AI summary) and `results[]` array.

### Output format

```markdown
## "<query>" 검색 결과

{answer if available — 1-2 sentence summary}

1. **[Title](url)**
   Content snippet

2. **[Title](url)**
   Content snippet

---
*Tavily Search · {N}건*
```

## Extract Mode

```bash
python3 <skill_dir>/scripts/tavily_api.py extract "<url>"
```

For multiple URLs, comma-separate: `extract "<url1>,<url2>"`.

Present the extracted markdown directly. For very long content, summarize the key points and note the full length.

## Notes

- `<skill_dir>` = this SKILL.md's parent directory
- Output language: Korean for all summaries
- TAVILY_API_KEY must be set in the environment
- On error, the script returns `{"error": "..."}` — relay the message to the user
