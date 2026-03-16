#!/usr/bin/env python3
"""Brave Search API client for web and video search.

Usage: python3 scripts/brave_search.py <command> [args...]

Commands:
  web <query> [--count=10] [--country=us] [--lang=en]
  video <query> [--count=5] [--country=us] [--lang=en]
  news <query> [--count=5] [--country=us] [--lang=en]
"""

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE_URL = "https://api.search.brave.com/res/v1"


def get_api_key():
    key = os.environ.get("BRAVE_API_KEY")
    if not key:
        error_exit("BRAVE_API_KEY environment variable not set")
    return key


def error_exit(msg):
    json.dump({"error": msg}, sys.stdout)
    print()
    sys.exit(1)


def api_get(path, params):
    url = f"{BASE_URL}{path}"
    if params:
        url += "?" + urllib.parse.urlencode(
            {k: v for k, v in params.items() if v is not None}
        )
    req = urllib.request.Request(
        url,
        headers={
            "X-Subscription-Token": get_api_key(),
            "Accept": "application/json",
            "User-Agent": "brave-search-cli/1.0",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            err = json.loads(body)
        except json.JSONDecodeError:
            err: dict = {"error": body}
        err["status"] = str(e.code)
        return err


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


def cmd_web(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: web <query> [--count=10] [--country=us] [--lang=en]")
    query = " ".join(positional)
    params = {
        "q": query,
        "count": opts.get("count", "10"),
    }
    if "country" in opts:
        params["country"] = opts["country"]
    if "lang" in opts:
        params["search_lang"] = opts["lang"]
    result = api_get("/web/search", params)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_video(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: video <query> [--count=5] [--country=us] [--lang=en]")
    query = " ".join(positional)
    params = {
        "q": query,
        "count": opts.get("count", "5"),
    }
    if "country" in opts:
        params["country"] = opts["country"]
    if "lang" in opts:
        params["search_lang"] = opts["lang"]
    result = api_get("/videos/search", params)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_news(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: news <query> [--count=5] [--country=us] [--lang=en]")
    query = " ".join(positional)
    params = {
        "q": query,
        "count": opts.get("count", "5"),
    }
    if "country" in opts:
        params["country"] = opts["country"]
    if "lang" in opts:
        params["search_lang"] = opts["lang"]
    result = api_get("/news/search", params)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


COMMANDS = {
    "web": cmd_web,
    "video": cmd_video,
    "news": cmd_news,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        error_exit(f"Unknown command: {cmd}. Available: {', '.join(COMMANDS)}")
    COMMANDS[cmd](sys.argv[2:])
