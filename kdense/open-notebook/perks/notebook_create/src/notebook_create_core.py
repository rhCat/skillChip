#!/usr/bin/env python3
"""notebook_create_core — POST /api/notebooks via the vendored Open Notebook client.

Reads NB_NAME / NB_DESCRIPTION from the environment, calls
notebook_management.create_notebook, and writes the created notebook (or a
graceful error payload when the server is unreachable) as JSON to argv[1].
"""
import json
import os
import sys

import notebook_management as nm


def main():
    out_path = sys.argv[1]
    name = os.getenv("NB_NAME", "")
    description = os.getenv("NB_DESCRIPTION", "")
    try:
        notebook = nm.create_notebook(name, description)
        payload = {"tool": "notebook_create", "status": "ok", "notebook": notebook}
    except Exception as exc:  # server unreachable / HTTP error — degrade gracefully
        payload = {
            "tool": "notebook_create",
            "status": "unreachable",
            "error": str(exc),
            "request": {"name": name, "description": description},
        }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
