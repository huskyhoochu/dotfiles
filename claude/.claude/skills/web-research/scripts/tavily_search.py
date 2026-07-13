#!/usr/bin/env python3
"""Tavily REST API client for search, extract, and research.

Usage: python3 scripts/tavily_search.py <command> [args...]

Commands:
  search <query> [--depth=advanced] [--max=10] [--topic=general] [--domains=...] [--exclude=...] [--recency=week]
  extract <urls> [--query=topic] [--depth=basic]
  research <query> [--model=mini] [--timeout=120]
"""

import sys
import time

from _http import api_get, api_post, dump, error_exit, get_api_key, parse_args, run_cli

BASE_URL = "https://api.tavily.com"


def _headers():
    return {"Authorization": f"Bearer {get_api_key('TAVILY_API_KEY')}"}


def cmd_search(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: search <query> [--depth=advanced] [--max=10] [--topic=general] [--domains=...] [--exclude=...] [--recency=week]")
    payload = {
        "query": " ".join(positional),
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
    dump(api_post(f"{BASE_URL}/search", _headers(), payload, timeout=60))


def cmd_extract(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: extract <urls_comma_separated> [--query=topic] [--depth=basic]")
    payload = {
        "urls": positional[0].split(","),
        "extract_depth": opts.get("depth", "basic"),
        "format": "markdown",
    }
    if "query" in opts:
        payload["query"] = opts["query"]
    dump(api_post(f"{BASE_URL}/extract", _headers(), payload, timeout=120))


def cmd_research(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: research <query> [--model=mini] [--timeout=120]")
    timeout = int(opts.get("timeout", "120"))
    payload = {
        "input": " ".join(positional),
        "model": opts.get("model", "mini"),
    }
    result, status = api_post(f"{BASE_URL}/research", _headers(), payload, timeout=60, return_status=True)
    if status not in (200, 201):
        dump(result)
        return
    request_id = result.get("request_id")
    if not request_id:
        dump(result)
        return
    elapsed = 0
    poll_interval = 5
    while elapsed < timeout:
        time.sleep(poll_interval)
        elapsed += poll_interval
        poll_result = api_get(f"{BASE_URL}/research/{request_id}", _headers())
        if poll_result.get("status") == "completed":
            dump(poll_result)
            return
    error_exit(f"Research timed out after {timeout}s (request_id: {request_id})")


COMMANDS = {
    "search": cmd_search,
    "extract": cmd_extract,
    "research": cmd_research,
}

if __name__ == "__main__":
    run_cli(__doc__, COMMANDS, sys.argv)
