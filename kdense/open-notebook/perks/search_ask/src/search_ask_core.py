#!/usr/bin/env python3
"""search_ask_core — POST /api/search/ask/simple via the vendored client.

Reads ASK_QUERY from the environment, calls chat_interaction.ask_question, and
writes the AI answer (or a graceful error payload when the server is
unreachable) as JSON to argv[1].
"""
import json
import os
import sys

import chat_interaction as ci


def main():
    out_path = sys.argv[1]
    query = os.getenv("ASK_QUERY", "")
    try:
        result = ci.ask_question(query)
        payload = {"tool": "search_ask", "status": "ok", "query": query, "answer": result}
    except Exception as exc:  # server unreachable / HTTP error — degrade gracefully
        payload = {
            "tool": "search_ask",
            "status": "unreachable",
            "error": str(exc),
            "request": {"query": query},
        }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
