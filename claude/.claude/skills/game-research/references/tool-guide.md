# Tool Guide

This skill shares scripts with the `web-research` skill. All scripts are located at `../web-research/scripts/` relative to this skill directory.

Resolve the absolute path at runtime:
```bash
SCRIPT_DIR="$(cd "$(dirname "<this-skill-path>")" && cd ../web-research/scripts && pwd)"
```

For full script documentation (parameters, options, caveats), see `../web-research/references/tool-guide.md`.

## Quick Reference

| Role | Script | Key options |
|------|--------|-------------|
| AI overview + citations | `perplexity_search.py ask` | `--context=high` |
| Cross-source analysis | `perplexity_search.py reason` | `--effort=high --context=high` |
| Web search | `brave_search.py web` | `--count=10` |
| Video search | `brave_search.py video` | `--count=8` |
| News search | `brave_search.py news` | `--count=5` |
| Refinement search | `tavily_search.py search` | `--depth=basic --max=10` |
| Content extraction | `tavily_search.py extract` | `--query=<topic>` |
| Fallback research | `tavily_search.py research` | `--model=mini` |
| Timestamp | `perplexity_search.py timestamp` | `--tz=Asia/Seoul` |

## Required Environment Variables

- `PERPLEXITY_API_KEY`
- `TAVILY_API_KEY`
- `BRAVE_API_KEY`
