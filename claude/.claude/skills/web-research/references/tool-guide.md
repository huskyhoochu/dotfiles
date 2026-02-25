# Tool Guide

Consolidated reference for all tools used in this pipeline: roles, parameters, and caveats.

## Role Assignment

| Role | Tool | Strength |
|------|------|----------|
| AI-synthesized overview + citations | `perplexity_ask` | Fast summary with source URLs |
| Cross-source analysis + gap detection | `perplexity_reason` | Admits gaps rather than hallucinating |
| URL collection | `tavily_search` | Clean results with content excerpts |
| Page content extraction | `tavily_extract` | URL → markdown, `query` param for relevance reranking |
| Video discovery | `supadata.py search` | YouTube search with filters (type, sort, limit) |
| Video metadata | `supadata.py video` | Title, stats (views/likes), tags, channel |
| Video transcript | `supadata.py transcript` | All languages, auto-fallback |
| Transcript translation | `supadata.py translate` | Cross-language transcript (paid plan) |
| Timestamp | `get_current_time` | Report date and recency awareness |

## Tool Details

### Perplexity

#### `perplexity_ask`
- **Purpose**: Step 1 initial overview. Returns AI-synthesized summary with numbered citation URLs.
- **Recommended params**: `search_context_size: "high"` (research tasks need rich context)
- **Caveat**: Occasionally overconfident — cross-validate key claims with other sources.

#### `perplexity_reason`
- **Purpose**: Step 4 cross-source analysis. Best for source conflicts, comparisons/trade-offs, and gap identification.
- **Strength**: Explicitly admits when evidence is insufficient (flags gaps instead of hallucinating).
- **Recommended params**: `search_context_size: "high"`

#### `perplexity_search`
- **Purpose**: Raw search results as URLs + snippets. Verbose content per result.
- **Note**: Not typically used in this pipeline — `tavily_search` and `perplexity_ask` cover its role.

#### `perplexity_research`
- **Note**: Not used in this pipeline due to high cost (30s+) and redundancy with the multi-step approach.

### Tavily

#### `tavily_search`
- **Purpose**: Step 1 web search. Returns clean, well-structured results.
- **Recommended params**: `search_depth: "advanced"`, `max_results: 10`

#### `tavily_extract`
- **Purpose**: Step 3 content extraction. URL list → markdown conversion.
- **Core value**: `query` parameter reranks extracted chunks by relevance, reducing noise from long pages.
- **Recommended params**: `query: "<research topic>"`

#### `tavily_research`
- **Purpose**: Fallback mode only. Single-call alternative when main pipeline fails.
- **Recommended params**: `model: "mini"` (cost efficiency)

#### `tavily_crawl`
- **Caveat**: Fails on SPA/JS-rendered sites (React, Next.js, Mintlify, Docusaurus, etc.). Only works on static HTML.
- **Alternative**: Use `tavily_extract` on individual URLs instead.

#### `tavily_map`
- **Caveat**: Same SPA limitation as `tavily_crawl`.
- **Alternative**: Check `/sitemap.xml` directly via `tavily_extract`.

### YouTube (via `scripts/supadata.py`)

All YouTube data is fetched via `scripts/supadata.py` (Supadata REST API). Run with Bash tool.

#### `supadata.py search`
- **Purpose**: Step 1 video search.
- **Example**: `scripts/supadata.py search "Claude Code" --type=video --limit=5`
- **Options**: `--type=` (video|channel|playlist|all), `--limit=` (default 5), `--sort=` (relevance|rating|date|views)
- **Returns**: JSON with `results[]` containing `{id, title, description, thumbnail, duration, viewCount, uploadDate, channel}`

#### `supadata.py video`
- **Purpose**: Step 3 video metadata.
- **Example**: `scripts/supadata.py video dQw4w9WgXcQ`
- **Accepts**: Video ID or full YouTube URL.
- **Returns**: JSON with `{title, description, viewCount, likeCount, tags[], channel, duration, uploadDate}`
- **Note**: No comment data available. Use `viewCount`/`likeCount` as engagement proxy.

#### `supadata.py transcript`
- **Purpose**: Step 3 video transcript.
- **Example**: `scripts/supadata.py transcript dQw4w9WgXcQ --lang=en --text`
- **Options**: `--lang=` (ISO 639-1 code, always specify to avoid wrong language), `--text` (plain text mode, recommended)
- **Returns**: JSON with `{content, lang, availableLangs[]}`
- **Caveat**: Without `--lang`, may return any available language. Always pass `--lang=en` for English content.

#### `supadata.py translate`
- **Purpose**: Translate transcript to another language.
- **Example**: `scripts/supadata.py translate dQw4w9WgXcQ --lang=en --text`
- **Options**: `--lang=` (required, target language), `--text` (plain text mode)
- **Caveat**: Requires paid Supadata plan. If `upgrade-required` error returned, skip gracefully.

#### `supadata.py channel`
- **Purpose**: Channel metadata lookup.
- **Example**: `scripts/supadata.py channel @RickAstleyYT`
- **Accepts**: Channel handle (@name), channel ID, or URL.
- **Returns**: JSON with `{id, name, description, handle, subscriberCount, videoCount, viewCount}`

### Time

#### `get_current_time`
- **Purpose**: Step 0 timestamp collection.
- **Recommended params**: `timezone: "Asia/Seoul"`
