#!/usr/bin/env python3
"""Supadata REST API client for YouTube data.

Usage: python3 scripts/supadata.py <command> [args...]

Commands:
  search <query> [--type=video] [--limit=5] [--sort=relevance]
  video <id_or_url>
  transcript <id_or_url> [--lang=en] [--text]
  translate <id_or_url> --lang=<lang> [--text]
  channel <id_or_url>
"""

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE_URL = "https://api.supadata.ai/v1"


def get_api_key():
    key = os.environ.get("SUPADATA_API_KEY")
    if not key:
        error_exit("SUPADATA_API_KEY environment variable not set")
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
            "x-api-key": get_api_key(),
            "User-Agent": "supadata-cli/1.0",
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
            err = {"error": body}
        err["status"] = e.code
        return err


def extract_video_id(id_or_url):
    """Extract YouTube video ID from URL or return as-is."""
    if id_or_url.startswith(("http://", "https://")):
        parsed = urllib.parse.urlparse(id_or_url)
        if "youtu.be" in parsed.hostname:
            return parsed.path.lstrip("/")
        qs = urllib.parse.parse_qs(parsed.query)
        if "v" in qs:
            return qs["v"][0]
        return id_or_url
    return id_or_url


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
        error_exit(
            "Usage: search <query> [--type=video] [--limit=5] [--sort=relevance]"
        )
    query = " ".join(positional)
    params = {
        "query": query,
        "type": opts.get("type", "video"),
        "limit": opts.get("limit", "5"),
        "sortBy": opts.get("sort", "relevance"),
    }
    result = api_get("/youtube/search", params)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_video(args):
    positional, _ = parse_args(args)
    if not positional:
        error_exit("Usage: video <id_or_url>")
    vid = extract_video_id(positional[0])
    result = api_get("/youtube/video", {"id": vid})
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_transcript(args):
    positional, opts = parse_args(args)
    if not positional:
        error_exit("Usage: transcript <id_or_url> [--lang=en] [--text]")
    vid = extract_video_id(positional[0])
    url = f"https://www.youtube.com/watch?v={vid}"
    params = {"url": url}
    if "lang" in opts:
        params["lang"] = opts["lang"]
    if opts.get("text"):
        params["text"] = "true"
    result = api_get("/transcript", params)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_translate(args):
    positional, opts = parse_args(args)
    if not positional or "lang" not in opts:
        error_exit("Usage: translate <id_or_url> --lang=<lang> [--text]")
    vid = extract_video_id(positional[0])
    params = {"videoId": vid, "lang": opts["lang"]}
    if opts.get("text"):
        params["text"] = "true"
    result = api_get("/youtube/transcript/translate", params)
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


def cmd_channel(args):
    positional, _ = parse_args(args)
    if not positional:
        error_exit("Usage: channel <id_or_url>")
    result = api_get("/youtube/channel", {"id": positional[0]})
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()


COMMANDS = {
    "search": cmd_search,
    "video": cmd_video,
    "transcript": cmd_transcript,
    "translate": cmd_translate,
    "channel": cmd_channel,
}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0)
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        error_exit(f"Unknown command: {cmd}. Available: {', '.join(COMMANDS)}")
    COMMANDS[cmd](sys.argv[2:])
