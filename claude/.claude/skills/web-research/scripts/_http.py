"""Shared helpers for web-research API scripts.

Each sibling script imports from here (`from _http import ...`) — running a
script by path puts this directory on sys.path, so no packaging is needed.
"""

import json
import sys
import os
import urllib.error
import urllib.parse
import urllib.request
from typing import NoReturn


def get_api_key(env_var):
    key = os.environ.get(env_var)
    if not key:
        error_exit(f"{env_var} environment variable not set")
    return key


def error_exit(msg) -> NoReturn:
    json.dump({"error": msg}, sys.stdout)
    print()
    sys.exit(1)


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


def _error_body(e):
    body = e.read().decode()
    try:
        err = json.loads(body)
        if not isinstance(err, dict):
            err = {"error": err}
    except json.JSONDecodeError:
        err = {"error": body}
    err["status"] = str(e.code)
    return err


def api_get(url, headers, params=None, timeout=30):
    if params:
        url += "?" + urllib.parse.urlencode(
            {k: v for k, v in params.items() if v is not None}
        )
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return _error_body(e)
    except (urllib.error.URLError, TimeoutError) as e:
        return {"error": f"Connection failed: {e}"}


def api_post(url, headers, body, timeout=30, return_status=False):
    """POST JSON. Returns the response dict, or (dict, http_status) when
    return_status=True (0 status on connection failure)."""
    all_headers = {"Content-Type": "application/json", **headers}
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers=all_headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            result = json.loads(resp.read())
            return (result, resp.status) if return_status else result
    except urllib.error.HTTPError as e:
        err = _error_body(e)
        return (err, e.code) if return_status else err
    except (urllib.error.URLError, TimeoutError) as e:
        err = {"error": f"Connection failed: {e}"}
        return (err, 0) if return_status else err


def run_cli(doc, commands, argv):
    """Standard entry point: dispatch argv to the commands dict."""
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(doc.strip() if doc else "")
        sys.exit(0)
    cmd = argv[1]
    if cmd not in commands:
        error_exit(f"Unknown command: {cmd}. Available: {', '.join(commands)}")
    commands[cmd](argv[2:])


def dump(result):
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    print()
