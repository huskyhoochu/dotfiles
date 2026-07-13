---
name: quick-search
description: |
  Simple web search and page content extraction. Searches Tavily (keyword) and
  Exa (neural) concurrently and merges the results — clean, organized output
  without deep analysis or cross-source verification.
  Three triggers: a quick lookup ("검색해줘", "찾아봐", "search for", "look up"),
  checking recent news, or extracting the content of a URL the user provides
  ("이 페이지 내용 가져와").
  For comprehensive multi-source research with cross-verification and
  synthesis, use web-research instead.
user-invocable: true
argument-hint: "<query_or_url> [--news] [--limit=N] [--recency=week]"
---

# Quick Search

Fast web search (Tavily + Exa in parallel) and page extraction. No subagents, no cross-verification — just clean merged results.

## Mode Detection

- Argument starts with `http://` or `https://` → **Extract mode**
- Otherwise → **Search mode**

## Search Mode

Run both engines concurrently in a single Bash call — Tavily catches keyword matches, Exa catches semantic matches keyword search misses:

```bash
python3 <scripts>/tavily_search.py search "<query>" --depth=basic --max=5 --answer > /tmp/qs-tavily.json &
python3 <scripts>/exa_search.py search "<query>" --count=5 --highlights > /tmp/qs-exa.json &
wait
```

**Flags passed through from user arguments (Tavily side only — Exa has no equivalents):**
- `--news` → add `--news` (switches topic to news)
- `--limit=N` → map to Tavily `--max=N` and Exa `--count=N` (default 5)
- `--recency=week` → time filter (day, week, month, year)
- `--domains=a.com,b.com` → restrict to specific domains

Tavily returns an `answer` field (AI summary) and `results[]`; Exa returns `results[]` (use `highlights[0]` as the content snippet if present).

**Merge**: dedup by URL (normalize trailing slash), Tavily order first, then Exa-only finds appended. If one engine errors, present the other's results alone and note the failure in the footer.

### Output format

```markdown
## "<query>" 검색 결과

{Tavily answer if available — 1-2 sentence summary}

1. **[Title](url)**
   Content snippet

2. **[Title](url)**
   Content snippet

---
*Tavily + Exa · {dedup 후 N}건*
```

## Extract Mode

```bash
python3 <scripts>/tavily_search.py extract "<url>"
```

For multiple URLs, comma-separate: `extract "<url1>,<url2>"`.

Present the extracted markdown directly. For very long content, summarize the key points and note the full length.

## Notes

- `<scripts>` = `<this SKILL.md's parent directory>/../web-research/scripts` — quick-search shares the web-research skill's API scripts (single source of truth for Tavily/Exa clients)
- Output language: Korean for all summaries
- TAVILY_API_KEY and EXA_API_KEY must be set in the environment
- On error, the script returns `{"error": "..."}` — relay the message to the user
