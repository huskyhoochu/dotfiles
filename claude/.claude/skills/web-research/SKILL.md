---
name: web-research
description: "Research any keyword/topic by orchestrating Perplexity, Tavily, and Brave Search API in a sequential pipeline to produce a comprehensive Korean-language report. Suited for tech trends, product comparisons, latest news. Invoke with /research <keyword> [--brief]."
user_invocable: true
argument: "<keyword_or_topic> [--brief]"
---

# Web Research Agent

A research agent that orchestrates **Perplexity**, **Tavily**, and **Brave Search API** via Python CLI scripts (`scripts/`) in a sequential pipeline to produce a comprehensive Korean-language research report.

## Core Rules

- **Output language**: Report = Korean, search queries = strategy below, internal reasoning = English
- **Search query language**: English keyword → English search. Korean keyword (contains U+AC00-U+D7AF) → Step 1 in Korean, Step 2c adds an English translation query
- **Argument parsing**: `--brief` flag → Brief Mode (Steps 0 + 1 + 4 only). Default: Full Report Mode (Steps 0-5)
- **Tool reference**: See `references/tool-guide.md` for tool details, parameters, and caveats

## Full Report Mode — Sequential Pipeline

### Step 0: Timestamp

Run `scripts/perplexity_search.py timestamp --tz=Asia/Seoul` for the report's `{date}` field and recency awareness.

### Step 1: Initial Discovery

Run three calls **in parallel**:

1. **Perplexity ask** — Run `scripts/perplexity_search.py ask "<query>" --context=high` — AI-synthesized overview + citation URLs
2. **Brave web search** — Run `scripts/brave_search.py web "<query>" --count=10` — URL discovery
3. **Brave video search** — Run `scripts/brave_search.py video "<query>" --count=5`

**News topic detection** (conditional parallel call): If the query contains time-sensitive keywords (흥행, 출시, 발표, 업데이트, 사건, 논란, 속보, release, launch, announce, breaking, etc.) or the Perplexity overview centers on recent events:
- **Brave news** — Run `scripts/brave_search.py news "<query>" --count=5` as an additional call

Post-processing:
- Extract preliminary overview/summary from Perplexity response
- **Extract key entities** (people, products, technologies, companies) → refinement terms for Step 2
- Merge unique URLs from Perplexity + Brave web
- Collect video results from Brave (titles, URLs, metadata)
- If Brave news was called, merge news results into source_matrix articles[] (leverage date metadata)
- Deduplicate across all sources

### Step 2: Source Classification & Query Refinement

**2a. Classify URLs** by pattern matching (refer to `references/source-classification.md`):
- Video: `youtube.com/watch`, `youtu.be/`, etc.
- Community: `reddit.com`, `forum`, `stackoverflow`, etc.
- Article: everything else

**2b. Merge video sources**: Combine video URLs from web search (2a) + Brave video search (Step 1). Deduplicate.

**2c. Targeted refinement** (conditional): If Step 1 overview revealed specific subtopics/terms that differ from the original keyword, run **one** additional search. Skip if original results already cover the topic well.

| Condition | API | Rationale |
|-----------|-----|-----------|
| General refinement (subtopic deep-dive) | `scripts/tavily_search.py search "<refined>" --depth=basic --max=10` | Relevance score for quality assessment |
| News refinement (time-sensitive subtopic) | `scripts/brave_search.py news "<refined>" --count=5` | Dedicated news endpoint with date metadata |
| Korean → English translation supplement | `scripts/brave_search.py web "<english query>" --count=10` | Broad English-language coverage |

**Build source_matrix** (input for Step 3):
```
articles[]  — {url, title}
videos[]    — {url, title, source, description}
community[] — {url, platform}
```

### Step 3: Deep Extraction

Extract content from each category. Run extractions **in parallel** across categories.

**Articles & Documents** (top 5 URLs):
- `scripts/tavily_search.py extract "url1,url2,..." --query="<research topic>"` (relevance reranking)

**Videos** (top 5 by relevance):
- Video information is already available from Brave Search results (title, description, source, view count, duration)
- For videos with URLs pointing to articles or pages with richer content, use `scripts/tavily_search.py extract` to get more detail
- No transcript extraction — rely on video descriptions and metadata from search results

**Community Discussions** (top 3 URLs):
- `scripts/tavily_search.py extract "url1,url2,..." --query="<research topic>"`

### Step 4: Synthesis & Analysis

Combine Step 1 AI overview + Step 3 extracted content for cross-source analysis.

**`perplexity_search.py reason` decision table:**

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

After output, use `AskUserQuestion` to ask whether to save (ask in Korean):
- **Don't save** — do nothing
- **Save to file** — user provides an absolute path → Write the already-output report text verbatim (do NOT re-generate or re-format)

## Brief Mode (--brief)

Run: Step 0 (timestamp) → Step 1 (initial discovery) → Step 4 (quick synthesis using own reasoning, no additional script call needed)

Generate output following `references/brief-template.md`, then run the same save prompt as Step 5.

## Fallback Mode

**Entry conditions** (any one triggers):
- Step 3 successful extractions ≤ **2**
- Both Perplexity and Tavily **unresponsive**

Use `scripts/tavily_search.py research "<query>" --model=mini` as a single-call alternative. Note in the report that fallback mode was used. This is a last resort — the full pipeline produces higher quality results.

## Error Handling

- If a specific tool or script call fails, skip that source and note it in the report's Gaps section
- If no video results found, skip video section entirely
- If Tavily extract fails for a URL, try the next URL in the list
- A single tool failure should never stop the entire pipeline
