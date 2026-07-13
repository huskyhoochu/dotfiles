---
name: pg-aiguide
description: |
  Provides AI-optimized PostgreSQL expertise: semantic search across official
  PostgreSQL/TimescaleDB/PostGIS documentation (version-aware) and curated best-practice
  skills for schema design, indexing, and query patterns. Equivalent to the
  pg-aiguide MCP server (Claude Code `timescale/pg-aiguide` plugin). Use when
  writing PostgreSQL schemas, queries, migrations, or working with TimescaleDB/PostGIS.
  Trigger on: PostgreSQL questions, schema design, table creation, indexing,
  hypertable setup, PostGIS, pgvector, PostgreSQL performance.
user-invocable: true
argument-hint: "<query_or_skill> [--mode=search|skill] [--source=postgres_17|tiger|postgis_3.4]"
---

# pg-aiguide — PostgreSQL Best Practices & Documentation

AI-optimized PostgreSQL expertise for coding assistants. Provides semantic search over versioned PostgreSQL docs and curated skills for common patterns.

## Workflow

### Mode A: Documentation Search (default)

Semantic search across PostgreSQL, TimescaleDB, and PostGIS docs:

```bash
python3 <skill_dir>/scripts/pg_aiguide.py search "<query>" --source=postgres_17 --limit=5
```

**Sources:**

| Source | Coverage |
|--------|----------|
| `postgres_17` | PostgreSQL 17 official docs |
| `postgres_16` | PostgreSQL 16 official docs |
| `postgres_15` | PostgreSQL 15 official docs |
| `postgres_14` | PostgreSQL 14 official docs |
| `tiger` | TimescaleDB docs |
| `postgis_3.4` | PostGIS 3.4 docs |

### Mode B: Curated Skills

List available skills:

```bash
python3 <skill_dir>/scripts/pg_aiguide.py skills
```

Get a specific skill:

```bash
python3 <skill_dir>/scripts/pg_aiguide.py skill <skill_name>
```

### Available Skills

| Skill | Description |
|-------|-------------|
| `design-postgres-tables` | Schema design — constraints, indexes, types, normalization |
| `design-postgis-tables` | PostGIS spatial schema design |
| `find-hypertable-candidates` | Identify tables suitable for TimescaleDB hypertables |
| `migrate-postgres-tables-to-hypertables` | Migrate standard tables → hypertables |
| `pgvector-semantic-search` | Vector/semantic search with pgvector |
| `postgres-hybrid-text-search` | Full-text + semantic hybrid search |
| `postgres` | General PostgreSQL best practices |
| `setup-timescaledb-hypertables` | TimescaleDB hypertable setup & config |

## Typical Usage Pattern

1. **Schema design**: Use `skill design-postgres-tables` to get best practices before writing CREATE TABLE statements
2. **Specific feature**: Use `search "your query"` for targeted documentation
3. **TimescaleDB**: Use `skill setup-timescaledb-hypertables` + `search "..." --source=tiger`
4. **PostGIS**: Use `skill design-postgis-tables` + `search "..." --source=postgis_3.4`

## Notes

- `<skill_dir>` = this SKILL.md's parent directory
- No API key required — uses the public pg-aiguide MCP server at `mcp.tigerdata.com/docs`
- `search` uses semantic (vector) search by default for best relevance
- If the MCP server is unreachable, `skill` falls back to fetching from GitHub raw
- Output language: Korean for summaries, English for code/docs
- The skills are AI-optimized and teach modern PostgreSQL 14-17 features (IDENTITY columns, NULLS NOT DISTINCT, generated columns, etc.)
