# Tool Guide

Consolidated reference for all tools used in this pipeline: roles, parameters, and caveats.

All scripts are in `scripts/` and run via the Bash tool. Each requires its corresponding API key environment variable.

## Role Assignment

| Role | Tool | Strength |
|------|------|----------|
| AI-synthesized overview + citations | `perplexity_search.py ask` | Fast summary with source URLs |
| Cross-source analysis + gap detection | `perplexity_search.py reason` | Admits gaps rather than hallucinating |
| URL collection (Step 1) | `brave_search.py web` | Low-cost web search, broad coverage |
| Refinement search (Step 2c) | `tavily_search.py search` | Quality assessment via relevance score |
| Page content extraction | `tavily_search.py extract` | URL → markdown, `--query` for relevance reranking |
| Fallback research | `tavily_search.py research` | Single-call alternative when main pipeline fails |
| Video discovery | `brave_search.py video` | Video results with metadata (title, duration, views) |
| News discovery (Step 1 conditional + Step 2c) | `brave_search.py news` | Date metadata for time-sensitive topics |
| Timestamp | `perplexity_search.py timestamp` | Report date and recency awareness |

## Tool Details

### Perplexity (via `scripts/perplexity_search.py`)

Requires `PERPLEXITY_API_KEY` environment variable. Run with Bash tool.

#### `perplexity_search.py ask`
- **Purpose**: Step 1 initial overview. Returns AI-synthesized summary with numbered citation URLs.
- **Usage**: `scripts/perplexity_search.py ask "<query>" [--context=high] [--recency=month] [--domains=a.com,b.com]`
- **Options**: `--context` (search context size, default: "high"), `--recency` (filter: day/week/month/year), `--domains` (comma-separated domain filter)
- **Caveat**: Occasionally overconfident — cross-validate key claims with other sources.

#### `perplexity_search.py reason`
- **Purpose**: Step 4 cross-source analysis. Best for source conflicts, comparisons/trade-offs, and gap identification.
- **Usage**: `scripts/perplexity_search.py reason "<query>" [--effort=high] [--context=high]`
- **Options**: `--effort` (reasoning effort, default: "high"), `--context` (search context size, default: "high")
- **Strength**: Explicitly admits when evidence is insufficient (flags gaps instead of hallucinating).

#### `perplexity_search.py timestamp`
- **Purpose**: Step 0 timestamp collection.
- **Usage**: `scripts/perplexity_search.py timestamp [--tz=Asia/Seoul]`
- **Options**: `--tz` (timezone name, default: "Asia/Seoul"). Supported: Asia/Seoul, Asia/Tokyo, America/New_York, America/Chicago, America/Denver, America/Los_Angeles, Europe/London, Europe/Paris, Europe/Berlin, UTC
- **Returns**: JSON with `timezone`, `datetime` (ISO 8601), `day_of_week`

### Tavily (via `scripts/tavily_search.py`)

Requires `TAVILY_API_KEY` environment variable. Run with Bash tool.

#### `tavily_search.py search`
- **Purpose**: Step 2c refinement search. Assesses subtopic result quality via relevance score. Default `--depth=basic`.
- **Usage**: `scripts/tavily_search.py search "<query>" [--depth=basic] [--max=10] [--topic=general] [--domains=...] [--exclude=...] [--recency=week]`
- **Options**: `--depth` (basic/advanced, default: "basic"), `--max` (max results, default: 10), `--topic` (general/news/finance, default: "general"), `--domains` (include domains), `--exclude` (exclude domains), `--recency` (time_range: day/week/month/year)

#### `tavily_search.py extract`
- **Purpose**: Step 3 content extraction. URL list → markdown conversion.
- **Usage**: `scripts/tavily_search.py extract "url1,url2,url3" [--query=topic] [--depth=basic]`
- **Options**: `--query` (reranks extracted chunks by relevance, reducing noise), `--depth` (basic/advanced, default: "basic")
- **Core value**: `--query` parameter reranks extracted chunks by relevance, reducing noise from long pages.

#### `tavily_search.py research`
- **Purpose**: Fallback mode only. Single-call alternative when main pipeline fails.
- **Usage**: `scripts/tavily_search.py research "<query>" [--model=mini] [--timeout=120]`
- **Options**: `--model` (mini/pro/auto, default: "mini"), `--timeout` (max polling wait in seconds, default: 120)
- **Note**: Async operation — script handles polling automatically. May take 30-120 seconds.

### Brave Search (via `scripts/brave_search.py`)

Requires `BRAVE_API_KEY` environment variable. Run with Bash tool.

#### `brave_search.py video`
- **Purpose**: Step 1 video discovery.
- **Example**: `scripts/brave_search.py video "Claude Code" --count=5`
- **Options**: `--count=` (default 5), `--country=` (e.g., us, kr), `--lang=` (e.g., en, ko)
- **Returns**: JSON with video results containing title, URL, description, source, duration, view count, thumbnail

#### `brave_search.py web`
- **Purpose**: Step 1 primary URL collection. Low-cost web search with broad coverage.
- **Example**: `scripts/brave_search.py web "Claude Code tutorial" --count=10`
- **Options**: `--count=` (default 10), `--country=`, `--lang=`
- **Returns**: JSON with web results containing title, URL, description, metadata

#### `brave_search.py news`
- **Purpose**: Step 1 conditional news collection + Step 2c news refinement. Called when time-sensitive topics detected.
- **Example**: `scripts/brave_search.py news "AI regulation" --count=5`
- **Options**: `--count=` (default 5), `--country=`, `--lang=`
- **Returns**: JSON with news results containing title, URL, description, date
