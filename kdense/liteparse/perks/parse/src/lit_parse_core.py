#!/usr/bin/env python3
"""
lit_parse_core — vendored core for the liteparse `parse` perk.

Parses a single document/PDF with the LiteParse engine (PyPI liteparse==2.0.0),
emitting the documented output: layout-preserved text or structured JSON with
per-page text_items (bounding boxes, font metadata, optional OCR confidence).

Local only, no network. If the `liteparse` package is not importable, this exits
0 after writing a graceful placeholder so the governed contract still holds.

Usage:
    lit_parse_core.py INPUT_FILE FORMAT OUT_JSON [OUT_TXT]
        FORMAT  : "text" | "json"
        OUT_JSON: always written (structured result or placeholder)
        OUT_TXT : optional; written with layout-preserved text when FORMAT=text
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _text_item_dict(item) -> dict:
    return {
        "text": getattr(item, "text", None),
        "x": getattr(item, "x", None),
        "y": getattr(item, "y", None),
        "width": getattr(item, "width", None),
        "height": getattr(item, "height", None),
        "font_name": getattr(item, "font_name", None),
        "font_size": getattr(item, "font_size", None),
        "confidence": getattr(item, "confidence", None),
    }


def _result_to_dict(result) -> dict:
    return {
        "text": getattr(result, "text", ""),
        "pages": [
            {
                "page_num": p.page_num,
                "width": p.width,
                "height": p.height,
                "text": p.text,
                "text_items": [_text_item_dict(i) for i in p.text_items],
            }
            for p in getattr(result, "pages", [])
        ],
    }


def main(argv) -> int:
    if len(argv) < 3:
        print("usage: lit_parse_core.py INPUT_FILE FORMAT OUT_JSON [OUT_TXT]", file=sys.stderr)
        return 2

    input_file = argv[0]
    fmt = (argv[1] or "text").lower()
    out_json = Path(argv[2])
    out_txt = Path(argv[3]) if len(argv) > 3 and argv[3] else None

    try:
        from liteparse import LiteParse  # type: ignore
    except Exception as exc:  # package absent at runtime
        placeholder = {
            "status": "skipped",
            "reason": "liteparse package not importable: %s" % exc,
            "input": input_file,
            "format": fmt,
        }
        out_json.write_text(json.dumps(placeholder, indent=2), encoding="utf-8")
        if out_txt is not None:
            out_txt.write_text("", encoding="utf-8")
        return 0

    parser = LiteParse(output_format="json" if fmt == "json" else "text", quiet=True)
    result = parser.parse(input_file)
    payload = _result_to_dict(result)
    out_json.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    if fmt == "text" and out_txt is not None:
        out_txt.write_text(payload.get("text", ""), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
