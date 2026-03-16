#!/usr/bin/env python3
"""Perplexity Sonar API client and timestamp utility.

Usage: python3 scripts/perplexity_search.py <command> [args...]

Commands:
  ask <query> [--context=high] [--recency=month] [--domains=arxiv.org,nature.com]
  reason <query> [--effort=high] [--context=high]
  timestamp [--tz=Asia/Seoul]
"""

import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone


def get_api_key():
    key = os.environ.get("PERPLEXITY_API_KEY")
    if not key:
        error_exit("PERPLEXITY_API_KEY environment variable not set")
    return key


def error_exit(msg):
    json.dump({"error": msg}, sys.stdout)
    print()
    sys.exit(1)


def api_post(payload):
    url = "https://api.perplexity.ai/chat/completions"
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
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        try:
            err = json.loads(body)
        except json.JSONDecodeError:
            err = {"error": body}
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


def cmd_ask(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: ask <query> [--context=high] [--recency=month] [--domains=a.com,b.com]")
    query = " ".join(positional)
    payload = {
        "model": "sonar-pro",
        "messages": [{"role": "user", "content": query}],
        "return_citations": True,
        "web_search_options": {
            "search_context_size": opts.get("context", "high"),
        },
    }
    if "recency" in opts:
        payload["search_recency_filter"] = opts["recency"]
    if "domains" in opts:
        payload["search_domain_filter"] = opts["domains"].split(",")
    result = api_post(payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_reason(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: reason <query> [--effort=high] [--context=high]")
    query = " ".join(positional)
    payload = {
        "model": "sonar-reasoning-pro",
        "messages": [{"role": "user", "content": query}],
        "return_citations": True,
        "reasoning_effort": opts.get("effort", "high"),
        "web_search_options": {
            "search_context_size": opts.get("context", "high"),
        },
    }
    result = api_post(payload)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


TIMEZONE_OFFSETS = {
    "Asia/Seoul": 9,
    "Asia/Tokyo": 9,
    "America/New_York": -5,
    "America/Chicago": -6,
    "America/Denver": -7,
    "America/Los_Angeles": -8,
    "Europe/London": 0,
    "Europe/Paris": 1,
    "Europe/Berlin": 1,
    "UTC": 0,
}

DAYS_KO = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


def cmd_timestamp(args):
    _, opts = parse_args(args)
    tz_name = opts.get("tz", "Asia/Seoul")
    offset_hours = TIMEZONE_OFFSETS.get(tz_name)
    if offset_hours is None:
        error_exit(f"Unknown timezone: {tz_name}. Available: {', '.join(TIMEZONE_OFFSETS)}")
    tz = timezone(timedelta(hours=offset_hours))
    now = datetime.now(tz)
    result = {
        "timezone": tz_name,
        "datetime": now.isoformat(timespec="seconds"),
        "day_of_week": DAYS_KO[now.weekday()],
    }
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


COMMANDS = {
    "ask": cmd_ask,
    "reason": cmd_reason,
    "timestamp": cmd_timestamp,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        error_exit(f"Unknown command: {cmd}. Available: {', '.join(COMMANDS)}")
    COMMANDS[cmd](sys.argv[2:])
