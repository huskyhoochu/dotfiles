# Tool Guide

Consolidated reference for all MCP tools used in this pipeline: roles, parameters, and caveats.

## Role Assignment

| Role | Tool | Strength |
|------|------|----------|
| AI-synthesized overview + citations | `perplexity_ask` | Fast summary with source URLs |
| Cross-source analysis + gap detection | `perplexity_reason` | Admits gaps rather than hallucinating |
| URL collection | `tavily_search` | Clean results with content excerpts |
| Page content extraction | `tavily_extract` | URL → markdown, `query` param for relevance reranking |
| Video discovery | `search_youtube` | Active YouTube search independent of web results |
| Video metadata + summary | `get_video` | Reliable across all languages (~300 tokens) |
| Video transcript | `get_transcript` | Detailed content for English videos |
| Community sentiment | `get_comments` | Summarized comment analysis across all languages |
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

### YouTube

#### `search_youtube`
- **Purpose**: Step 1 video search. Works well across all languages.
- **Recommended params**: `max_results: 5`, `order: "relevance"`

#### `get_video`
- **Purpose**: Step 3 video metadata + language-agnostic summary (~300 tokens).
- **Strength**: Reliable information source for non-English videos. Always call first.

#### `get_transcript`
- **Purpose**: Step 3 detailed transcript for English videos.
- **Recommended params**: `mode: "summary"`
- **Caveat**: For non-English videos (especially Korean/CJK), summary mode returns raw STT dump (10,000+ chars of garbled text). Do not use for non-English videos.

#### `get_comments`
- **Purpose**: Step 3 community reaction collection.
- **Recommended params**: `summarize: true`, `top_n: 10`
- **Strength**: Works reliably across all languages.

### Time

#### `get_current_time`
- **Purpose**: Step 0 timestamp collection.
- **Recommended params**: `timezone: "Asia/Seoul"`
