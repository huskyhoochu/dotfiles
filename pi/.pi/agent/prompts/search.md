---
description: 웹 검색 — Tavily+Exa 스크립트를 bash로 직접 실행 (로컬 모델용)
argument-hint: "<query>"
---
Search the web for: $@

Use the bash tool to run EXACTLY these three commands in one call. Do NOT use the web_search tool. Do NOT look for a tool named quick-search or search.

```bash
date '+오늘 날짜: %Y-%m-%d (%A)'
python3 ~/dotfiles/claude/.claude/skills/web-research/scripts/tavily_search.py search "$@" --max=5 --answer
python3 ~/dotfiles/claude/.claude/skills/web-research/scripts/exa_search.py search "$@" --count=5 --highlights
```

The first line prints today's real date — trust it over your training data when judging what is "current", "recent", or "upcoming". Both python commands print JSON. Write a Korean summary from that JSON:

1. If Tavily's `answer` field exists, start with it (1-2 sentences).
2. List results as `**[title](url)** — 한 줄 요약`. Dedup by URL: Tavily results first, then Exa-only results.
3. End with the footer: `*Tavily + Exa · N건*`

If a script prints `{"error": ...}`, mention the error briefly and use the other engine's results alone.
