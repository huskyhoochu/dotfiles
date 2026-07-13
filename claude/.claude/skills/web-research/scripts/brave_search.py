#!/usr/bin/env python3
"""Brave Search API client for web and video search.

Usage: python3 scripts/brave_search.py <command> [args...]

Commands:
  web <query> [--count=10] [--country=us] [--lang=en]
  video <query> [--count=5] [--country=us] [--lang=en]
  news <query> [--count=5] [--country=us] [--lang=en]
"""

import sys

from _http import api_get, dump, error_exit, get_api_key, parse_args, run_cli

BASE_URL = "https://api.search.brave.com/res/v1"


def _search(path, args, usage, default_count):
    positional, opts = parse_args(args)
    if not positional:
        error_exit(usage)
    params = {
        "q": " ".join(positional),
        "count": opts.get("count", default_count),
    }
    if "country" in opts:
        params["country"] = opts["country"]
    if "lang" in opts:
        params["search_lang"] = opts["lang"]
    headers = {
        "X-Subscription-Token": get_api_key("BRAVE_API_KEY"),
        "Accept": "application/json",
        "User-Agent": "brave-search-cli/1.0",
    }
    dump(api_get(f"{BASE_URL}{path}", headers, params))


def cmd_web(args):
    _search("/web/search", args, "Usage: web <query> [--count=10] [--country=us] [--lang=en]", "10")


def cmd_video(args):
    _search("/videos/search", args, "Usage: video <query> [--count=5] [--country=us] [--lang=en]", "5")


def cmd_news(args):
    _search("/news/search", args, "Usage: news <query> [--count=5] [--country=us] [--lang=en]", "5")


COMMANDS = {
    "web": cmd_web,
    "video": cmd_video,
    "news": cmd_news,
}

if __name__ == "__main__":
    run_cli(__doc__, COMMANDS, sys.argv)
