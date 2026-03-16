#!/usr/bin/env python3
"""Tavily REST API client for search, extract, and research.

Usage: python3 scripts/tavily_search.py <command> [args...]

Commands:
  search <query> [--depth=advanced] [--max=10] [--topic=general] [--domains=...] [--exclude=...] [--recency=week]
  extract <urls> [--query=topic] [--depth=basic]
  research <query> [--model=mini] [--timeout=120]
"""

import json
import os
import sys
import time
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


def api_request(method, path, payload=None):
    url = f"{BASE_URL}{path}"
    data = json.dumps(payload).encode("utf-8") if payload else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {get_api_key()}",
            "Content-Type": "application/json",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read()), resp.status
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            err = json.loads(body)
        except json.JSONDecodeError:
            err = {"error": body}
        err["status"] = str(e.code)
        return err, e.code


def parse_args(args):
    """Parse --key=value and --flag style arguments."""
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
        error_exit("Usage: search <query> [--depth=advanced] [--max=10] [--topic=general] [--domains=...] [--exclude=...] [--recency=week]")
    query = " ".join(positional)
    payload = {
        "query": query,
        "search_depth": opts.get("depth", "advanced"),
        "max_results": int(opts.get("max", "10")),
        "topic": opts.get("topic", "general"),
    }
    if "domains" in opts:
        payload["include_domains"] = opts["domains"].split(",")
    if "exclude" in opts:
        payload["exclude_domains"] = opts["exclude"].split(",")
    if "recency" in opts:
        payload["time_range"] = opts["recency"]
    result, _ = api_request("POST", "/search", payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_extract(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: extract <urls_comma_separated> [--query=topic] [--depth=basic]")
    urls = positional[0].split(",")
    payload = {
        "urls": urls,
        "extract_depth": opts.get("depth", "basic"),
        "format": "markdown",
    }
    if "query" in opts:
        payload["query"] = opts["query"]
    result, _ = api_request("POST", "/extract", payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_research(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: research <query> [--model=mini] [--timeout=120]")
    query = " ".join(positional)
    timeout = int(opts.get("timeout", "120"))
    payload = {
        "input": query,
        "model": opts.get("model", "mini"),
    }
    result, status = api_request("POST", "/research", payload)
    if status not in (200, 201):
        json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return
    request_id = result.get("request_id")
    if not request_id:
        json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
        print()
        return
    elapsed = 0
    poll_interval = 5
    while elapsed < timeout:
        time.sleep(poll_interval)
        elapsed += poll_interval
        poll_result, _ = api_request("GET", f"/research/{request_id}")
        if poll_result.get("status") == "completed":
            json.dump(poll_result, sys.stdout, ensure_ascii=False, indent=2)
            print()
            return
    error_exit(f"Research timed out after {timeout}s (request_id: {request_id})")


COMMANDS = {
    "search": cmd_search,
    "extract": cmd_extract,
    "research": cmd_research,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        error_exit(f"Unknown command: {cmd}. Available: {', '.join(COMMANDS)}")
    COMMANDS[cmd](sys.argv[2:])
