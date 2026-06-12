#!/usr/bin/env python3
"""
pg-aiguide client for pi agent skills.
Calls the pg-aiguide MCP server at TigerData for PostgreSQL/TimescaleDB/PostGIS
documentation search and curated best-practice skills.

Public MCP server — no API key required.
Endpoint: https://mcp.tigerdata.com/docs

Usage:
  python3 pg_aiguide.py search "<query>" [--source=postgres_17|tiger|postgis_3.4] [--limit=N]
  python3 pg_aiguide.py skill <skill_name>
  python3 pg_aiguide.py skills
"""

import json
import os
import sys
import urllib.request
import urllib.error

MCP_URL = "https://mcp.tigerdata.com/docs"

# Known skill names (from https://github.com/timescale/pg-aiguide/tree/main/skills)
SKILLS = {
    "design-postgres-tables": "Schema design best practices for PostgreSQL tables (constraints, indexes, types, normalization)",
    "design-postgis-tables": "Schema design best practices for PostGIS spatial tables (geometry columns, spatial indexes, SRID conventions)",
    "find-hypertable-candidates": "Identify tables in an existing schema that are good candidates for TimescaleDB hypertables",
    "migrate-postgres-tables-to-hypertables": "Step-by-step guide for migrating standard PostgreSQL tables to TimescaleDB hypertables",
    "pgvector-semantic-search": "Best practices for semantic/vector search with pgvector (embedding storage, ANN indexes, hybrid search)",
    "postgres-hybrid-text-search": "Implementing hybrid text search in PostgreSQL (full-text search + semantic search combined)",
    "postgres": "General PostgreSQL best practices — modern features, performance, security, schema design",
    "setup-timescaledb-hypertables": "Setting up and configuring TimescaleDB hypertables (chunk intervals, compression, retention policies)",
}


def _json_rpc(method: str, params: dict = None, session_id: str = None) -> tuple[dict, str | None]:
    """Make a JSON-RPC call to the MCP endpoint. Returns (result, session_id)."""
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params or {},
        "id": 1,
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(MCP_URL, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json, text/event-stream")
    if session_id:
        req.add_header("Mcp-Session-Id", session_id)

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            new_session_id = resp.headers.get("Mcp-Session-Id", session_id)
            raw = resp.read().decode()

            # Handle SSE-style responses: might have "data: {...}" lines
            result_data = None
            for line in raw.strip().split("\n"):
                line = line.strip()
                if line.startswith("data:"):
                    line = line[5:].strip()
                if line.startswith("{"):
                    try:
                        result_data = json.loads(line)
                        break
                    except json.JSONDecodeError:
                        continue
            if result_data is None:
                return {"error": "No JSON found in response", "raw": raw[:500]}, new_session_id
            return result_data, new_session_id
    except urllib.error.HTTPError as e:
        body = e.read().decode() if e.fp else ""
        return {"error": f"HTTP {e.code}", "detail": body[:500]}, session_id
    except Exception as e:
        return {"error": str(e)}, session_id


def _initialize() -> str | None:
    """Initialize MCP session and return session ID."""
    result, session_id = _json_rpc("initialize", {
        "protocolVersion": "2024-11-05",
        "capabilities": {},
        "clientInfo": {"name": "pi-pg-aiguide-skill", "version": "1.0.0"},
    })
    if "error" in result:
        # Try without initialize (some servers don't require it)
        return None
    return session_id


def cmd_search(args: list[str]):
    """Search PostgreSQL/TimescaleDB/PostGIS documentation."""
    source = "postgres_17"
    limit = 5
    query_parts = []

    for a in args:
        if a.startswith("--source="):
            source = a.split("=", 1)[1]
        elif a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])
        else:
            query_parts.append(a)

    query = " ".join(query_parts)
    if not query:
        print(json.dumps({"error": "Usage: search <query> [--source=postgres_17|tiger|postgis_3.4] [--limit=N]"}, ensure_ascii=False))
        sys.exit(1)

    session_id = _initialize()

    result, _ = _json_rpc("tools/call", {
        "name": "search_docs",
        "arguments": {
            "query": query,
            "source": source,
        },
    }, session_id=session_id)

    if "error" in result:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        sys.exit(1)

    # Extract content from MCP tool result
    content = result.get("result", {}).get("content", [])
    if not content and isinstance(result.get("result"), dict):
        content = result.get("result", {}).get("structuredContent", {}).get("results", [])

    simplified = []
    for item in content[:limit]:
        if isinstance(item, dict):
            simplified.append({
                "text": item.get("text", str(item)[:500]),
                "source": item.get("source", ""),
            })
        elif isinstance(item, str):
            simplified.append({"text": item[:500]})

    output = {
        "query": query,
        "source": source,
        "results": simplified,
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_skill(args: list[str]):
    """Retrieve a specific pg-aiguide skill."""
    skill_name = args[0] if args else ""
    if not skill_name:
        print(json.dumps({"error": "Usage: skill <skill_name>"}, ensure_ascii=False))
        sys.exit(1)

    if skill_name not in SKILLS:
        print(json.dumps({
            "error": f"Unknown skill: {skill_name}",
            "available": list(SKILLS.keys()),
        }, ensure_ascii=False))
        sys.exit(1)

    # Try fetching from MCP first
    session_id = _initialize()
    result, _ = _json_rpc("tools/call", {
        "name": "view_skill",
        "arguments": {"skill": skill_name},
    }, session_id=session_id)

    if "error" not in result:
        content = result.get("result", {}).get("content", [])
        output = {
            "skill": skill_name,
            "description": SKILLS.get(skill_name, ""),
            "content": content,
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return

    # Fallback: fetch from GitHub raw
    fallback_url = f"https://raw.githubusercontent.com/timescale/pg-aiguide/main/skills/{skill_name}/SKILL.md"
    try:
        with urllib.request.urlopen(fallback_url, timeout=15) as resp:
            markdown = resp.read().decode()
            output = {
                "skill": skill_name,
                "description": SKILLS.get(skill_name, ""),
                "source": "github",
                "content": markdown[:10000],  # Truncate very long skills
            }
            print(json.dumps(output, ensure_ascii=False, indent=2))
    except Exception as e:
        print(json.dumps({"error": f"Failed to fetch skill: {e}"}, ensure_ascii=False))


def cmd_skills(_args: list[str]):
    """List all available skills."""
    print(json.dumps({
        "skills": {k: v for k, v in SKILLS.items()},
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: pg_aiguide.py <search|skill|skills> ...")
        sys.exit(1)

    cmd = sys.argv[1]
    rest = sys.argv[2:]

    if cmd == "search":
        cmd_search(rest)
    elif cmd == "skill":
        cmd_skill(rest)
    elif cmd == "skills":
        cmd_skills(rest)
    else:
        print(f"Unknown command: {cmd}")
        print("Available: search, skill, skills")
        sys.exit(1)
