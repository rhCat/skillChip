#!/usr/bin/env python3
"""
lit_screenshot_core — vendored core for the liteparse `screenshot` perk.

Renders document pages to PNG files using the LiteParse engine
(PyPI liteparse==2.0.0). Useful for multimodal agents that must see figures,
complex tables, or handwriting that text extraction alone misses.

Local only, no network. If the `liteparse` package is not importable, this exits
0 after writing a graceful placeholder manifest so the governed contract holds.

Usage:
    lit_screenshot_core.py INPUT_FILE TARGET_PAGES DPI OUT_DIR MANIFEST_JSON
        TARGET_PAGES : "" (all) or "1,3,5" / "1-5,10"
        DPI          : integer render DPI (e.g. 150)
        OUT_DIR      : directory for page_<n>.png files
        MANIFEST_JSON: always written (list of rendered pages or placeholder)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _parse_pages(spec: str):
    spec = (spec or "").strip()
    if not spec:
        return None
    pages = []
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            pages.extend(range(int(a), int(b) + 1))
        else:
            pages.append(int(part))
    return pages or None


def main(argv) -> int:
    if len(argv) < 5:
        print("usage: lit_screenshot_core.py INPUT_FILE TARGET_PAGES DPI OUT_DIR MANIFEST_JSON", file=sys.stderr)
        return 2

    input_file = argv[0]
    page_numbers = _parse_pages(argv[1])
    try:
        dpi = float(argv[2]) if argv[2] else 150.0
    except ValueError:
        dpi = 150.0
    out_dir = Path(argv[3])
    manifest = Path(argv[4])
    out_dir.mkdir(parents=True, exist_ok=True)

    try:
        from liteparse import LiteParse  # type: ignore
    except Exception as exc:  # package absent at runtime
        manifest.write_text(
            json.dumps(
                {
                    "status": "skipped",
                    "reason": "liteparse package not importable: %s" % exc,
                    "input": input_file,
                    "dpi": dpi,
                    "target_pages": argv[1] or "all",
                    "pages": [],
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        return 0

    parser = LiteParse(dpi=dpi, quiet=True)
    shots = parser.screenshot(input_file, page_numbers=page_numbers)
    rendered = []
    for s in shots:
        png = out_dir / ("page_%s.png" % s.page_num)
        png.write_bytes(s.image_bytes)
        rendered.append({"page_num": s.page_num, "width": s.width, "height": s.height, "file": png.name})
    manifest.write_text(
        json.dumps({"status": "ok", "input": input_file, "dpi": dpi, "pages": rendered}, indent=2),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
