# Source Classification Guide

## URL Pattern → Type Mapping

### Video Sources
| Pattern | Platform |
|---------|----------|
| `youtube.com/watch?v=` | YouTube |
| `youtu.be/` | YouTube (short URL) |
| `youtube.com/shorts/` | YouTube Shorts |
| `vimeo.com/` | Vimeo |

**Video ID Extraction:**
- `youtube.com/watch?v=VIDEO_ID` → extract `VIDEO_ID` from `v` parameter
- `youtu.be/VIDEO_ID` → extract path segment
- `youtube.com/shorts/VIDEO_ID` → extract path segment

### Community / Forum Sources
| Pattern | Platform |
|---------|----------|
| `reddit.com/r/` | Reddit |
| `news.ycombinator.com` | Hacker News |
| `stackoverflow.com` | Stack Overflow |
| `stackexchange.com` | Stack Exchange |
| `github.com/*/discussions` | GitHub Discussions |
| `github.com/*/issues` | GitHub Issues |
| `discourse.*` | Discourse forums |
| URL contains `forum` | Generic forum |
| URL contains `community` | Generic community |
| URL contains `discuss` | Generic discussion |

### Article / Document Sources
Everything not matching the above patterns falls into this category. Includes:
- News articles
- Blog posts
- Official documentation
- Academic papers
- Corporate announcements

## Extraction Strategy by Type

### Articles & Documents
- **Tool**: `tavily_extract` (default) or `tavily_crawl` (for official docs)
- **Batch**: Up to 5 URLs per call
- **Output**: Markdown content
- **Official docs upgrade**: If a URL matches `docs.*`, `*.readthedocs.io`, `developer.*`, or similar official documentation patterns, use `tavily_crawl` with `max_depth: 1`, `max_breadth: 5` to capture surrounding pages

### YouTube Videos
- **Discovery**: Actively searched via `search_youtube` in Step 1, supplemented by YouTube URLs found in web search results
- **Tools**: `youtube_get_transcript` (mode: summary) + `youtube_get_comments` (summarize: true)
- **Limit**: Top 3 videos (to manage context size)
- **Output**: Transcript summary + comment sentiment

### Community Discussions
- **Tool**: `tavily_extract`
- **Limit**: Top 3 threads
- **Output**: Discussion content in markdown

## Priority Rules

When more URLs are available than the extraction limits:
1. Prefer sources with higher relevance scores from the search results
2. Prefer recent content over older content
3. Prefer diverse platforms over multiple links from the same domain
4. Official documentation and primary sources take priority over secondary coverage
