#!/usr/bin/env python3
"""notebook_list_core — GET /api/notebooks via the vendored Open Notebook client.

Reads NB_ARCHIVED ("true"/"false") from the environment, calls
notebook_management.list_notebooks, and writes the notebook list (or a graceful
error payload when the server is unreachable) as JSON to argv[1].
"""
import json
import os
import sys

import notebook_management as nm


def main():
    out_path = sys.argv[1]
    archived = os.getenv("NB_ARCHIVED", "false").strip().lower() in ("1", "true", "yes")
    try:
        notebooks = nm.list_notebooks(archived=archived)
        payload = {
            "tool": "notebook_list",
            "status": "ok",
            "archived": archived,
            "count": len(notebooks),
            "notebooks": notebooks,
        }
    except Exception as exc:  # server unreachable / HTTP error — degrade gracefully
        payload = {
            "tool": "notebook_list",
            "status": "unreachable",
            "error": str(exc),
            "request": {"archived": archived},
        }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
