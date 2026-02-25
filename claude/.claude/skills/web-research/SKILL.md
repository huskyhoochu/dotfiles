---
name: web-research
description: "Research any keyword/topic by orchestrating Perplexity, Tavily, and YouTube MCP tools in a sequential pipeline to produce a comprehensive Korean-language report. Suited for tech trends, product comparisons, latest news. Invoke with /research <keyword> [--brief]."
user_invocable: true
argument: "<keyword_or_topic> [--brief]"
---

# Web Research Agent

A research agent that orchestrates three MCP tool families — **Perplexity**, **Tavily**, and **YouTube** — in a sequential pipeline to produce a comprehensive Korean-language research report.

## Core Rules

- **Output language**: Report = Korean, search queries = strategy below, internal reasoning = English
- **Search query language**: English keyword → English search. Korean keyword (contains U+AC00-U+D7AF) → Step 1 in Korean, Step 2c adds an English translation query
- **Argument parsing**: `--brief` flag → Brief Mode (Steps 0 + 1 + 4 only). Default: Full Report Mode (Steps 0-5)
- **Tool reference**: See `references/tool-guide.md` for tool details, parameters, and caveats

## Full Report Mode — Sequential Pipeline

### Step 0: Timestamp

Call `get_current_time` (timezone: "Asia/Seoul") for the report's `{date}` field and recency awareness.

### Step 1: Initial Discovery

Run three calls **in parallel**:

1. **`perplexity_ask`** — AI-synthesized overview + citation URLs (search_context_size: "high")
2. **`tavily_search`** — Web search (search_depth: "advanced", max_results: 10)
3. **`search_youtube`** — YouTube video search (max_results: 5, order: "relevance")

Post-processing:
- Extract preliminary overview/summary from Perplexity response
- **Extract key entities** (people, products, technologies, companies) → refinement terms for Step 2
- Merge unique URLs from Perplexity + Tavily
- Collect YouTube video IDs from search_youtube results
- Deduplicate across all sources

### Step 2: Source Classification & Query Refinement

**2a. Classify URLs** by pattern matching (refer to `references/source-classification.md`):
- Video: `youtube.com/watch`, `youtu.be/`, etc.
- Community: `reddit.com`, `forum`, `stackoverflow`, etc.
- Article: everything else

Extract `video_id` from YouTube URLs (v= parameter or youtu.be/ path segment).

**2b. Merge video sources**: Combine video IDs from web search URLs (2a) + search_youtube (Step 1). Deduplicate.

**2c. Targeted refinement** (conditional): If Step 1 overview revealed specific subtopics/terms that differ from the original keyword, run **one** additional `tavily_search` with refined query. Skip if original results already cover the topic well. For Korean keywords, also run one additional search with an English translation query.

**Build source_matrix** (input for Step 3):
```
articles[]  — {url, title}
videos[]    — {video_id, title, language_hint: "ko"|"en"|"other"}
community[] — {url, platform}
```

`language_hint` detection: Title contains Hangul (U+AC00-U+D7AF) or CJK characters → "ko" or "other". Otherwise → "en".

### Step 3: Deep Extraction

Extract content from each category. Run extractions **in parallel** across categories.

**Articles & Documents** (top 5 URLs):
- `tavily_extract` with `query` parameter set to research topic (relevance reranking)

**YouTube Videos** (top 3):
- All videos: `get_video` (metadata + summary) + `get_comments` (summarize: true)
- `language_hint == "en"`: also use `get_transcript` (mode: "summary")
- `language_hint == "ko"` or `"other"`: skip `get_transcript` (returns raw STT dump, wastes context)

**Community Discussions** (top 3 URLs):
- `tavily_extract` with `query` parameter set to research topic

### Step 4: Synthesis & Analysis

Combine Step 1 AI overview + Step 3 extracted content for cross-source analysis.

**`perplexity_reason` decision table:**

| Condition | Action |
|-----------|--------|
| Successful extractions ≥8 + source types ≥2 + clear consensus | Synthesize directly (skip) |
| Sources conflict OR comparison/trade-off topic | Required |
| Successful extractions ≤3 | Required (gap identification) |
| Otherwise | Recommended |

When used, include a concise findings summary in the prompt and ask it to identify: **consensus points**, **controversial areas**, **quantitative data**, and **evidence gaps**.

### Step 5: Report Generation & Save

Generate the final report following `references/report-template.md`.

**Rules:**
- Write the entire report in **Korean**
- Include all source URLs as clickable markdown links
- Confidence levels: High (3+ sources agree), Medium (1-2 sources), Low (single unverified claim)
- Output the report **directly in the chat response** first

After output, use `AskUserQuestion` to ask whether to save:
- **저장하지 않음** — do nothing
- **파일로 저장** — user provides an absolute path → Write the already-output report text verbatim (do NOT re-generate or re-format)

## Brief Mode (--brief)

Run: Step 0 (timestamp) → Step 1 (initial discovery) → Step 4 (quick synthesis using own reasoning, no additional MCP call needed)

Generate output following `references/brief-template.md`, then run the same save prompt as Step 5.

## Fallback Mode

**Entry conditions** (any one triggers):
- Step 3 successful extractions ≤ **2**
- Both Perplexity and Tavily **unresponsive**

Use `tavily_research` (model: "mini") as a single-call alternative. Note in the report that fallback mode was used. This is a last resort — the full pipeline produces higher quality results.

## Error Handling

- If a specific MCP tool fails, skip that source and note it in the report's Gaps section
- If no YouTube videos found, skip Step 3 video extraction entirely
- If Tavily extract fails for a URL, try the next URL in the list
- A single tool failure should never stop the entire pipeline
