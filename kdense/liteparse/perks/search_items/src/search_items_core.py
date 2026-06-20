#!/usr/bin/env python3
"""
search_items_core — vendored core for the liteparse `search_items` perk.

Self-contained stdlib reimplementation of liteparse.search_items: given a parsed
document JSON (pages[].text_items[] with x/y/width/height), find a phrase that may
span several adjacent text_items and return each match as a single merged
TextItem-shaped record with a combined bounding box.

Local only, stdlib only — runs offline without the liteparse package.

Usage:
    search_items_core.py PARSED_JSON PHRASE CASE_SENSITIVE OUT_JSON
        CASE_SENSITIVE : "1" for case-sensitive, anything else for insensitive
        OUT_JSON       : always written (list of matches, possibly empty)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _norm(s, case_sensitive):
    s = s or ""
    return s if case_sensitive else s.lower()


def _merge_bbox(items):
    xs = [i.get("x") for i in items if i.get("x") is not None]
    ys = [i.get("y") for i in items if i.get("y") is not None]
    x2s = [
        (i.get("x") or 0) + (i.get("width") or 0)
        for i in items
        if i.get("x") is not None
    ]
    y2s = [
        (i.get("y") or 0) + (i.get("height") or 0)
        for i in items
        if i.get("y") is not None
    ]
    x = min(xs) if xs else None
    y = min(ys) if ys else None
    w = (max(x2s) - x) if (x2s and x is not None) else None
    h = (max(y2s) - y) if (y2s and y is not None) else None
    return x, y, w, h


def search_items(items, phrase, case_sensitive=False):
    """Return merged matches for `phrase` across adjacent `items`."""
    target = _norm(phrase, case_sensitive).strip()
    if not target:
        return []
    matches = []
    n = len(items)
    for start in range(n):
        acc = ""
        used = []
        for j in range(start, n):
            piece = _norm(items[j].get("text", ""), case_sensitive)
            acc = (acc + " " + piece).strip() if acc else piece
            used.append(items[j])
            if target in acc:
                x, y, w, h = _merge_bbox(used)
                matches.append(
                    {
                        "text": phrase,
                        "x": x,
                        "y": y,
                        "width": w,
                        "height": h,
                        "item_count": len(used),
                    }
                )
                break
            if len(acc) > len(target) + 64:
                break
    return matches


def main(argv) -> int:
    if len(argv) < 4:
        print("usage: search_items_core.py PARSED_JSON PHRASE CASE_SENSITIVE OUT_JSON", file=sys.stderr)
        return 2

    parsed_json = Path(argv[0])
    phrase = argv[1]
    case_sensitive = argv[2] == "1"
    out = Path(argv[3])

    try:
        data = json.loads(parsed_json.read_text(encoding="utf-8"))
    except Exception as exc:
        out.write_text(
            json.dumps({"status": "error", "reason": str(exc), "matches": []}, indent=2),
            encoding="utf-8",
        )
        return 0

    results = []
    for page in data.get("pages", []):
        page_num = page.get("page_num")
        for m in search_items(page.get("text_items", []), phrase, case_sensitive):
            m["page_num"] = page_num
            results.append(m)

    out.write_text(
        json.dumps({"status": "ok", "phrase": phrase, "count": len(results), "matches": results}, indent=2),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
