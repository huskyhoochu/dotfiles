#!/usr/bin/env python3
"""Exa REST API client for neural search, similarity search, and direct answers.

Usage: python3 scripts/exa_search.py <command> [args...]

Commands:
  search <query> [--type=auto] [--count=10] [--highlights]
  findsimilar <url> [--count=10] [--highlights]
  answer <query>
"""

import json
import os
import sys
import urllib.error
import urllib.request


BASE_URL = "https://api.exa.ai"


def get_api_key():
    key = os.environ.get("EXA_API_KEY")
    if not key:
        error_exit("EXA_API_KEY environment variable not set")
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
            "x-api-key": get_api_key(),
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
        error_exit("Usage: search <query> [--type=auto] [--count=10] [--highlights]")
    query = " ".join(positional)
    payload = {
        "query": query,
        "type": opts.get("type", "auto"),
        "numResults": int(opts.get("count", "10")),
    }
    if "highlights" in opts:
        payload["contents"] = {"highlights": True}
    result = api_post("/search", payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


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
    result = api_post("/findSimilar", payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_answer(args):
    positional, _opts = parse_args(args)
    if not positional:
        error_exit("Usage: answer <query>")
    query = " ".join(positional)
    payload = {
        "query": query,
        "text": True,
    }
    result = api_post("/answer", payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


COMMANDS = {
    "search": cmd_search,
    "findsimilar": cmd_findsimilar,
    "answer": cmd_answer,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        error_exit(f"Unknown command: {cmd}. Available: {', '.join(COMMANDS)}")
    COMMANDS[cmd](sys.argv[2:])
