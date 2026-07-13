#!/usr/bin/env python3
"""Perplexity Sonar API client and timestamp utility.

Usage: python3 scripts/perplexity_search.py <command> [args...]

Commands:
  ask <query> [--context=high] [--recency=month] [--domains=arxiv.org,nature.com]
  reason <query> [--effort=high] [--context=high]
  timestamp [--tz=Asia/Seoul]
"""

import sys
from datetime import datetime, timedelta, timezone

from _http import api_post, dump, error_exit, get_api_key, parse_args, run_cli

API_URL = "https://api.perplexity.ai/chat/completions"


def _chat(payload):
    headers = {"Authorization": f"Bearer {get_api_key('PERPLEXITY_API_KEY')}"}
    return api_post(API_URL, headers, payload, timeout=180)


def cmd_ask(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: ask <query> [--context=high] [--recency=month] [--domains=a.com,b.com]")
    payload = {
        "model": "sonar-pro",
        "messages": [{"role": "user", "content": " ".join(positional)}],
        "return_citations": True,
        "web_search_options": {
            "search_context_size": opts.get("context", "high"),
        },
    }
    if "recency" in opts:
        payload["search_recency_filter"] = opts["recency"]
    if "domains" in opts:
        payload["search_domain_filter"] = opts["domains"].split(",")
    dump(_chat(payload))


def cmd_reason(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: reason <query> [--effort=high] [--context=high]")
    payload = {
        "model": "sonar-reasoning-pro",
        "messages": [{"role": "user", "content": " ".join(positional)}],
        "return_citations": True,
        "reasoning_effort": opts.get("effort", "high"),
        "web_search_options": {
            "search_context_size": opts.get("context", "high"),
        },
    }
    dump(_chat(payload))


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
    dump({
        "timezone": tz_name,
        "datetime": now.isoformat(timespec="seconds"),
        "day_of_week": DAYS_KO[now.weekday()],
    })


COMMANDS = {
    "ask": cmd_ask,
    "reason": cmd_reason,
    "timestamp": cmd_timestamp,
}

if __name__ == "__main__":
    run_cli(__doc__, COMMANDS, sys.argv)
