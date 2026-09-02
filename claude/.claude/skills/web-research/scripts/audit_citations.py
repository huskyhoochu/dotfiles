#!/usr/bin/env python3
"""Flag report sources the pipeline never collected.

Usage: python3 scripts/audit_citations.py <report.md> <workspace>

Reads every URL the workspace saw (source_matrix, refinement, extraction/*,
Perplexity citations) and appends `⚠️ 수집 목록에 없는 URL` to each line of the
출처 section whose link is not among them. Rewrites the report in place and
prints a one-line summary. Same rule as gem12-agents `research.report.ts`.
"""

import json
import os
import re
import sys


def urls_in(obj, out):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in ("url", "citations") and isinstance(v, str):
                out.add(v)
            else:
                urls_in(v, out)
    elif isinstance(obj, list):
        for v in obj:
            if isinstance(v, str) and v.startswith("http"):
                out.add(v)
            else:
                urls_in(v, out)


def known_urls(workspace):
    out = set()
    candidates = ["source_matrix.json", "refinement.json", "discovery/perplexity.json"]
    ext = os.path.join(workspace, "extraction")
    if os.path.isdir(ext):
        candidates += [os.path.join("extraction", f) for f in os.listdir(ext) if f.endswith(".json")]
    for rel in candidates:
        path = os.path.join(workspace, rel)
        if not os.path.exists(path):
            continue
        try:
            urls_in(json.load(open(path, encoding="utf-8")), out)
        except (json.JSONDecodeError, OSError):
            continue
    return {u.rstrip("/") for u in out}


def main():
    if len(sys.argv) != 3:
        print(__doc__.strip())
        sys.exit(2)
    report_path, workspace = sys.argv[1:3]
    known = known_urls(workspace)
    text = open(report_path, encoding="utf-8").read()
    heading = "## 출처" if "## 출처" in text else "## 주요 출처"
    at = text.find(heading)
    if at < 0:
        print("출처 절이 없다 — 감사 생략")
        return
    head, tail = text[:at], text[at:]
    unknown = 0
    lines = []
    for line in tail.split("\n"):
        m = re.search(r"\]\((https?://[^)\s]+)\)", line)
        if m and m.group(1).rstrip("/") not in known and "⚠️" not in line:
            unknown += 1
            line += " ⚠️ 수집 목록에 없는 URL"
        lines.append(line)
    open(report_path, "w", encoding="utf-8").write(head + "\n".join(lines))
    print(f"출처 감사: 수집 목록 {len(known)}건 대조, 목록 밖 {unknown}건 표시")


if __name__ == "__main__":
    main()
