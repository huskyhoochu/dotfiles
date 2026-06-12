#!/usr/bin/env python3
"""
Google Developer Knowledge API client for pi agent skills.
Searches Google's official developer documentation (Firebase, Google Cloud,
Android, Maps, etc.) for up-to-date references.

Environment:
  GOOGLE_DEVELOPER_KNOWLEDGE_API_KEY — API key from Google Cloud console
    (enable the Developer Knowledge API first: https://console.cloud.google.com/start/api?id=developerknowledge.googleapis.com)

Usage:
  python3 google_dev_api.py answer "<query>"
  python3 google_dev_api.py search "<query>" [--limit=N]
  python3 google_dev_api.py get <document_name> [<document_name>...]
"""

import json
import os
import sys
import urllib.request
import urllib.parse
import urllib.error

API_KEY = os.environ.get("GOOGLE_DEVELOPER_KNOWLEDGE_API_KEY", "")
BASE_URL = "https://developerknowledge.googleapis.com"


def _get_json(url: str) -> dict:
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode() if e.fp else ""
        return {"error": f"HTTP {e.code}", "detail": body[:500]}
    except Exception as e:
        return {"error": str(e)}


def _post_json(url: str, body: dict) -> dict:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body_text = e.read().decode() if e.fp else ""
        return {"error": f"HTTP {e.code}", "detail": body_text[:500]}
    except Exception as e:
        return {"error": str(e)}


def cmd_answer(args: list[str]):
    """Get a grounded AI answer to a query about Google developer products."""
    query = " ".join(args)
    if not query:
        print(json.dumps({"error": "Usage: answer <query>"}, ensure_ascii=False))
        sys.exit(1)

    url = f"{BASE_URL}/v1alpha:answerQuery?key={API_KEY}"
    result = _post_json(url, {"query": query})
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_search(args: list[str]):
    """Search Google developer documentation for relevant document chunks."""
    limit = 5
    query_parts = []

    for a in args:
        if a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])
        else:
            query_parts.append(a)

    query = " ".join(query_parts)
    if not query:
        print(json.dumps({"error": "Usage: search <query> [--limit=N]"}, ensure_ascii=False))
        sys.exit(1)

    url = f"{BASE_URL}/v1/documents:searchDocumentChunks?query={urllib.parse.quote(query)}&key={API_KEY}"
    result = _get_json(url)

    # Limit results and simplify output
    if "documentChunks" in result:
        chunks = result["documentChunks"][:limit]
        simplified = []
        for chunk in chunks:
            simplified.append({
                "content": chunk.get("content", ""),
                "parent": chunk.get("parent", ""),
                "title": chunk.get("title", chunk.get("parent", "").split("/")[-1] if chunk.get("parent") else ""),
            })
        result["documentChunks"] = simplified

    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_get(args: list[str]):
    """Retrieve full document content by document name(s)."""
    names = [a for a in args if not a.startswith("--")]
    if not names:
        print(json.dumps({"error": "Usage: get <document_name> [<document_name>...]"}, ensure_ascii=False))
        sys.exit(1)

    if len(names) == 1:
        # Single document: use get
        name = names[0]
        url = f"{BASE_URL}/v1/{urllib.parse.quote(name, safe='')}?key={API_KEY}"
        result = _get_json(url)
    else:
        # Multiple documents: use batchGet
        params = "&".join(f"names={urllib.parse.quote(n, safe='')}" for n in names)
        url = f"{BASE_URL}/v1/documents:batchGet?{params}&key={API_KEY}"
        result = _get_json(url)

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    if not API_KEY:
        print(json.dumps({
            "error": "GOOGLE_DEVELOPER_KNOWLEDGE_API_KEY is not set",
            "help": "Get an API key from https://console.cloud.google.com/apis/credentials after enabling the Developer Knowledge API"
        }, ensure_ascii=False))
        sys.exit(1)

    if len(sys.argv) < 2:
        print("Usage: google_dev_api.py <answer|search|get> ...")
        sys.exit(1)

    cmd = sys.argv[1]
    rest = sys.argv[2:]

    if cmd == "answer":
        cmd_answer(rest)
    elif cmd == "search":
        cmd_search(rest)
    elif cmd == "get":
        cmd_get(rest)
    else:
        print(f"Unknown command: {cmd}")
        print("Available: answer, search, get")
        sys.exit(1)
