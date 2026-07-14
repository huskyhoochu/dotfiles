---
description: PostgreSQL 문서·베스트프랙티스 검색 (pg-aiguide 스크립트)
argument-hint: "<question> [skill_name]"
---
PostgreSQL question: $@

Use the bash tool to run EXACTLY this command:

```bash
python3 ~/dotfiles/claude/.claude/skills/pg-aiguide/scripts/pg_aiguide.py search "$@" --source=postgres_17 --limit=3
```

It prints JSON with documentation excerpts. Answer the question in Korean based on those excerpts, citing the `source_url` of each excerpt you used.

If the user asks for a curated best-practice guide instead of a doc search, run one of these instead:

```bash
python3 ~/dotfiles/claude/.claude/skills/pg-aiguide/scripts/pg_aiguide.py skills          # list guides
python3 ~/dotfiles/claude/.claude/skills/pg-aiguide/scripts/pg_aiguide.py skill <name>    # fetch one guide
```
