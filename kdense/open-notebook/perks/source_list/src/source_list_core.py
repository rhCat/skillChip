#!/usr/bin/env python3
"""source_list_core — GET /api/sources via the vendored Open Notebook client.

Reads NOTEBOOK_ID (optional filter) and SOURCE_LIMIT from the environment, calls
source_ingestion.list_sources, and writes the source list (or a graceful error
payload when the server is unreachable) as JSON to argv[1].
"""
import json
import os
import sys

import source_ingestion as si


def main():
    out_path = sys.argv[1]
    notebook_id = os.getenv("NOTEBOOK_ID", "").strip() or None
    try:
        limit = int(os.getenv("SOURCE_LIMIT", "20"))
    except ValueError:
        limit = 20
    try:
        sources = si.list_sources(notebook_id=notebook_id, limit=limit)
        payload = {
            "tool": "source_list",
            "status": "ok",
            "notebook_id": notebook_id,
            "count": len(sources),
            "sources": sources,
        }
    except Exception as exc:  # server unreachable / HTTP error — degrade gracefully
        payload = {
            "tool": "source_list",
            "status": "unreachable",
            "error": str(exc),
            "request": {"notebook_id": notebook_id, "limit": limit},
        }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
