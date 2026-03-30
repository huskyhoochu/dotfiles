#!/usr/bin/env python3
"""Tavily API client for quick web search and page extraction.

Usage: python3 scripts/tavily_api.py <command> [args...]

Commands:
  search <query> [--limit=5] [--topic=general] [--recency=week] [--domains=a.com,b.com]
  extract <url>[,<url2>,...] [--query=relevance topic]
"""

import json
import os
import sys
import urllib.error
import urllib.request

BASE_URL = "https://api.tavily.com"


def get_api_key():
    key = os.environ.get("TAVILY_API_KEY")
    if not key:
        error_exit("TAVILY_API_KEY environment variable not set")
    return key


def error_exit(msg):
    json.dump({"error": msg}, sys.stdout)
    print()
    sys.exit(1)


def api_post(path, payload):
    url = f"{BASE_URL}{path}"
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {get_api_key()}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            err = json.loads(body)
        except json.JSONDecodeError:
            err = {"error": body}
        err["status"] = str(e.code)
        return err
    except urllib.error.URLError as e:
        return {"error": f"Connection failed: {e.reason}"}


def parse_args(args):
    opts = {}
    positional = []
    for arg in args:
        if arg.startswith("--"):
            if "=" in arg:
                k, v = arg[2:].split("=", 1)
                opts[k] = v
            else:
                opts[arg[2:]] = True
        else:
            positional.append(arg)
    return positional, opts


def cmd_search(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: search <query> [--limit=5] [--topic=general] [--recency=week] [--domains=a.com,b.com]")
    query = " ".join(positional)
    payload = {
        "query": query,
        "search_depth": "basic",
        "max_results": int(opts.get("limit", "5")),
        "topic": opts.get("topic", "general"),
        "include_answer": True,
    }
    if "recency" in opts:
        payload["time_range"] = opts["recency"]
    if "domains" in opts:
        payload["include_domains"] = opts["domains"].split(",")
    if "news" in opts:
        payload["topic"] = "news"
    result = api_post("/search", payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_extract(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: extract <url>[,<url2>,...] [--query=relevance topic]")
    urls = positional[0].split(",")
    payload = {
        "urls": urls,
        "extract_depth": "basic",
        "format": "markdown",
    }
    if "query" in opts:
        payload["query"] = opts["query"]
    result = api_post("/extract", payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


COMMANDS = {
    "search": cmd_search,
    "extract": cmd_extract,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__ or "")
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        error_exit(f"Unknown command: {cmd}. Available: {', '.join(COMMANDS)}")
    COMMANDS[cmd](sys.argv[2:])
