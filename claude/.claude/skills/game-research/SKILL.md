---
name: game-research
description: "Research any game title, genre, or gaming topic by orchestrating parallel subagents across Perplexity, Tavily, and Brave Search API to produce a comprehensive Korean-language gaming report. Specialized for game reviews, release info, patch notes, player sentiment, esports, and industry trends. Each research phase runs as independent subagents for true parallel execution and context isolation. Use this skill whenever the user asks about games, gaming hardware, esports, game development, or wants to research any game-related topic — even if they don't explicitly say 'game research'. Invoke with /game-research <keyword> [--brief]."
user_invocable: true
argument: "<game_or_topic> [--brief]"
---

# Game Research Orchestrator

Orchestrates parallel subagents (via the Agent tool) across **Perplexity**, **Tavily**, and **Brave Search API** to produce a comprehensive Korean-language gaming research report. Shares the same Python scripts as the `web-research` skill — the scripts are generic API wrappers.

## Core Rules

- **Output language**: Report = Korean, search queries = strategy below, internal reasoning = English
- **Search query language**: English keyword → English search. Korean keyword (contains U+AC00-U+D7AF) → Korean search in Phase 1, English supplement in Phase 2
- **Argument parsing**: `--brief` flag → Brief Mode (Phase 0 + 1 + Quick Synthesis). Default: Full Report Mode (Phase 0-4)
- **Script location**: `../web-research/scripts/` — shared with web-research skill
- **Tool reference**: See `references/tool-guide.md` for script details, parameters, and caveats

## Architecture

```
Phase 1: Discovery ─────────── 2 subagents in parallel
  ├─ Perplexity Discovery       (AI overview + entity extraction)
  └─ Brave Discovery            (web + video + news)
              │
              ▼  workspace JSON handoff
Phase 2: Classification ────── orchestrator inline (lightweight)
              │
              ▼
Phase 3: Deep Extraction ───── 1-2 subagents in parallel
  ├─ Article Extractor          (top 8 article URLs)
  └─ Community Extractor        (top 5 community URLs, if any)
              │
              ▼
Phase 4: Synthesis ─────────── 1 subagent
  └─ Report Synthesizer         (cross-source analysis + report generation)
```

## Workspace

Create at pipeline start:

```bash
WORKSPACE="/tmp/game-research-$(date +%s)"
mkdir -p "$WORKSPACE"/{discovery,extraction}
```

All subagents save structured JSON here. The orchestrator reads these files to coordinate between phases.

**Data contract:**
```
$WORKSPACE/
├── meta.json                # {timestamp, query, language, mode, query_type}
├── discovery/
│   ├── perplexity.json      # {overview, citations[], entities[], is_news_topic}
│   ├── brave_web.json       # raw Brave web API response
│   ├── brave_video.json     # raw Brave video API response
│   └── brave_news.json      # raw Brave news API response (if applicable)
├── source_matrix.json       # {articles[], videos[], community[], reviews[]}
├── refinement.json          # refinement search results (if applicable)
└── extraction/
    ├── articles.json        # {results[{url, title, content}]}
    └── community.json       # {results[{url, platform, content}]}
```

## Full Report Mode — Orchestration Pipeline

### Phase 0: Setup

1. Parse arguments: extract keyword and `--brief` flag
2. Run `scripts/perplexity_search.py timestamp --tz=Asia/Seoul` for the report's `{date}` field
   - Where `scripts/` = `<this skill's parent>/../web-research/scripts/` (resolve the path)
3. Create workspace directory
4. Detect search language: Korean if keyword contains Hangul (U+AC00-U+D7AF)
5. Classify query type for search expansion:
   | Query pattern | Type | Search expansion |
   |---------------|------|------------------|
   | Specific game title (e.g., "엘든 링", "Elden Ring") | `title` | Add "review", "metacritic", "gameplay" |
   | Genre/category (e.g., "소울라이크", "roguelike 2026") | `genre` | Add "best", "recommendations", "upcoming" |
   | Industry topic (e.g., "게임 구독 서비스", "UE6") | `industry` | Add "analysis", "comparison", "trend" |
   | Esports (e.g., "LCK 2026", "Valorant Champions") | `esports` | Add "results", "standings", "teams" |
   | Hardware (e.g., "스팀덱 OLED", "PS5 Pro") | `hardware` | Add "review", "specs", "comparison" |
6. Detect gaming news keywords: 출시, 패치, 업데이트, DLC, 확장팩, 시즌, 발표, 논란, 서비스종료, release, launch, patch, update, nerf, buff, hotfix, early access, beta, etc.
7. Save `meta.json` to workspace (include `query_type`)

### Phase 1: Parallel Discovery

Spawn **two subagents simultaneously** using the Agent tool. Read each agent template from `agents/`, construct the prompt with the variables below, and launch both in a single message.

**Subagent A — Perplexity Discovery:**

Read `agents/discoverer-perplexity.md`. Spawn with these variables:
- `{query}`: the research keyword
- `{query_type}`: classified query type from Phase 0
- `{language}`: detected search language
- `{workspace}`: workspace path
- `{script_dir}`: path to `../web-research/scripts/` (resolved absolute path)

**Subagent B — Brave Discovery:**

Read `agents/discoverer-brave.md`. Spawn with these variables:
- `{query}`: the research keyword
- `{query_type}`: classified query type
- `{language}`: detected search language
- `{has_news_keywords}`: whether news keywords were detected in Phase 0
- `{workspace}`: workspace path
- `{script_dir}`: path to `../web-research/scripts/` (resolved absolute path)

**Wait for both subagents to complete before proceeding.**

### Phase 2: Classification & Refinement (inline)

This phase is lightweight enough to run inline in the orchestrator. No subagent needed.

1. Read `discovery/perplexity.json` and `discovery/brave_web.json` from workspace
2. Classify all URLs by pattern matching (refer to `references/source-classification.md`):
   - Video: YouTube, Twitch clips, etc.
   - Community: Reddit gaming subs, Steam community, 루리웹, 인벤, etc.
   - Review: Metacritic, OpenCritic, IGN, GameSpot, etc.
   - Article: everything else
3. Merge video sources: video URLs from web search + `discovery/brave_video.json`. Deduplicate.
4. If `discovery/brave_news.json` exists, merge news results into articles (leverage date metadata)
5. Deduplicate across all sources

**Refinement decision**: Read `discovery/perplexity.json` entities. If entities reveal subtopics not covered by initial results, run **one** refinement search inline:

| Condition | Script call |
|-----------|-------------|
| Missing platform-specific info | `scripts/tavily_search.py search "<game> <platform>" --depth=basic --max=10` |
| Competitive/multiplayer context | `scripts/brave_search.py web "<game> meta tier list" --count=10` |
| Missing review aggregation | `scripts/brave_search.py web "<game> metacritic opencritic review" --count=5` |
| Korean → English supplement | `scripts/brave_search.py web "<english query>" --count=10` |
| News/patch refinement | `scripts/brave_search.py news "<game> patch update" --count=5` |

Where `scripts/` = resolved path to `../web-research/scripts/`.

Save refinement results to `refinement.json`. Build and save `source_matrix.json`:
```json
{
  "articles": [{"url": "...", "title": "..."}],
  "reviews": [{"url": "...", "title": "...", "platform": "..."}],
  "videos": [{"url": "...", "title": "...", "source": "...", "description": "..."}],
  "community": [{"url": "...", "platform": "..."}]
}
```

### Phase 3: Parallel Extraction

Spawn extraction subagents simultaneously. Read `agents/extractor.md` for the template.

**Subagent C — Article Extractor:**
- `{category}`: "articles"
- `{urls}`: top 8 article URLs from source_matrix (comma-separated). Prioritize review sites and official sources.
- `{query}`: research topic (for relevance reranking)
- `{workspace}`: workspace path
- `{script_dir}`: resolved script directory path

**Subagent D — Community Extractor** (only if community URLs exist):
- `{category}`: "community"
- `{urls}`: top 5 community URLs from source_matrix (comma-separated)
- `{query}`: research topic
- `{workspace}`: workspace path
- `{script_dir}`: resolved script directory path

Video metadata is already available from Brave search results — no extraction subagent needed.

**Wait for all extraction subagents to complete.**

**Post-extraction: Build extraction coverage summary.** After extraction completes, build `extraction_coverage` to pass to the synthesizer:

```json
{
  "extracted": ["url1", "url2"],
  "failed": ["url3"],
  "skipped": ["url4", "url5", "..."]
}
```

### Phase 4: Synthesis

Spawn **one synthesis subagent**. Read `agents/synthesizer.md` for the template, and also read `references/report-template.md` to include in the prompt.

Provide the synthesizer with:
- `{workspace}`: workspace path
- `{query}`: research keyword
- `{query_type}`: classified query type
- `{timestamp}`: from Phase 0
- `{script_dir}`: resolved script directory path
- `{report_template}`: full contents of `references/report-template.md`
- `{source_matrix}`: contents of `source_matrix.json`
- `{perplexity_overview}`: the overview text from `discovery/perplexity.json`
- `{extracted_articles}`: contents of `extraction/articles.json`
- `{extracted_community}`: contents of `extraction/community.json` (if exists)
- `{video_metadata}`: video entries from source_matrix
- `{refinement_data}`: contents of `refinement.json` (if exists)
- `{extraction_coverage}`: the extraction coverage summary

The synthesizer decides whether to call `perplexity_search.py reason` based on:

| Condition | Action |
|-----------|--------|
| Extractions >= 8 + source types >= 2 + clear consensus | Synthesize directly (skip) |
| Sources conflict OR comparison topic (e.g., PS5 vs Xbox) | Required |
| Extractions <= 3 | Required (gap identification) |
| Otherwise | Recommended |

The synthesizer outputs the complete report text.

### Phase 5: Output & Save

1. Output the synthesizer's report directly in the chat response
2. Use `AskUserQuestion` to ask whether to save (in Korean):
   - Don't save → do nothing
   - Save to file → user provides path → Write the report verbatim

## Brief Mode (--brief)

Simplified pipeline — no extraction or deep synthesis:

1. **Phase 0**: Setup (same as full mode)
2. **Phase 1**: Parallel Discovery (same — spawn both subagents)
3. **Skip Phases 2-3**
4. **Quick Synthesis**: Read discovery results. The orchestrator synthesizes directly (no subagent needed for brief mode — the data volume is small enough). Generate output following `references/brief-template.md`.
5. **Output & Save**: Same as Phase 5

## Fallback Mode

**Entry conditions** (any one triggers):
- Phase 3 extraction subagents both return <= 2 successful extractions total
- Both Perplexity and Brave discovery subagents fail

Use `scripts/tavily_search.py research "<query>" --model=mini` as a single-call alternative. Note in the report that fallback mode was used.

## Error Handling

- If a subagent fails or times out, proceed with results from the successful subagent(s)
- If a specific script call fails within a subagent, the subagent should note the failure and continue
- If no video results found, skip video section entirely
- A single subagent failure should never stop the entire pipeline — degrade gracefully
