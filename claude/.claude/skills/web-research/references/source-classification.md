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

## Priority Rules

When more URLs are available than the extraction limits:
1. Prefer sources with higher relevance scores from the search results
2. Prefer recent content over older content
3. Prefer diverse platforms over multiple links from the same domain
4. Official documentation and primary sources take priority over secondary coverage
