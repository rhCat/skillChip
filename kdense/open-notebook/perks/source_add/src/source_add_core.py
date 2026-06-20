#!/usr/bin/env python3
"""source_add_core — POST /api/sources via the vendored Open Notebook client.

Ingests ONE source into a notebook. Reads NOTEBOOK_ID plus either SOURCE_URL or
SOURCE_TEXT (URL wins if both are set) from the environment, calls the matching
source_ingestion helper, and writes the created source (or a graceful error
payload when the server is unreachable) as JSON to argv[1].
"""
import json
import os
import sys

import source_ingestion as si


def main():
    out_path = sys.argv[1]
    notebook_id = os.getenv("NOTEBOOK_ID", "")
    url = os.getenv("SOURCE_URL", "").strip()
    text = os.getenv("SOURCE_TEXT", "")
    title = os.getenv("SOURCE_TITLE", "Text source")
    try:
        if url:
            source = si.add_url_source(notebook_id, url, process_async=False)
            kind = "url"
        else:
            source = si.add_text_source(notebook_id, title, text)
            kind = "text"
        payload = {"tool": "source_add", "status": "ok", "kind": kind, "source": source}
    except Exception as exc:  # server unreachable / HTTP error — degrade gracefully
        payload = {
            "tool": "source_add",
            "status": "unreachable",
            "error": str(exc),
            "request": {"notebook_id": notebook_id, "url": url, "has_text": bool(text)},
        }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
