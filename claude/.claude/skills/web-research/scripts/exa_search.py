#!/usr/bin/env python3
"""Exa REST API client for neural search, similarity search, and direct answers.

Usage: python3 scripts/exa_search.py <command> [args...]

Commands:
  search <query> [--type=auto] [--count=10] [--highlights]
  findsimilar <url> [--count=10] [--highlights]
  answer <query>
"""

import sys

from _http import api_post, dump, error_exit, get_api_key, parse_args, run_cli

BASE_URL = "https://api.exa.ai"


def _post(path, payload):
    headers = {"x-api-key": get_api_key("EXA_API_KEY")}
    return api_post(f"{BASE_URL}{path}", headers, payload)


def cmd_search(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: search <query> [--type=auto] [--count=10] [--highlights]")
    payload = {
        "query": " ".join(positional),
        "type": opts.get("type", "auto"),
        "numResults": int(opts.get("count", "10")),
    }
    if "highlights" in opts:
        payload["contents"] = {"highlights": True}
    dump(_post("/search", payload))


def cmd_findsimilar(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: findsimilar <url> [--count=10] [--highlights]")
    payload = {
        "url": positional[0],
        "numResults": int(opts.get("count", "10")),
    }
    if "highlights" in opts:
        payload["contents"] = {"highlights": True}
    dump(_post("/findSimilar", payload))


def cmd_answer(args):
    positional, _opts = parse_args(args)
    if not positional:
        error_exit("Usage: answer <query>")
    dump(_post("/answer", {"query": " ".join(positional), "text": True}))


COMMANDS = {
    "search": cmd_search,
    "findsimilar": cmd_findsimilar,
    "answer": cmd_answer,
}

if __name__ == "__main__":
    run_cli(__doc__, COMMANDS, sys.argv)
