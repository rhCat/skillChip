#!/usr/bin/env python3
"""search_query_core — POST /api/search via the vendored Open Notebook client.

Reads SEARCH_QUERY, SEARCH_TYPE ("vector"|"text"), and SEARCH_LIMIT from the
environment, calls chat_interaction.search_knowledge_base, and writes the search
results (or a graceful error payload when the server is unreachable) as JSON to
argv[1].
"""
import json
import os
import sys

import chat_interaction as ci


def main():
    out_path = sys.argv[1]
    query = os.getenv("SEARCH_QUERY", "")
    search_type = os.getenv("SEARCH_TYPE", "vector").strip() or "vector"
    try:
        limit = int(os.getenv("SEARCH_LIMIT", "5"))
    except ValueError:
        limit = 5
    try:
        results = ci.search_knowledge_base(query, search_type=search_type, limit=limit)
        payload = {
            "tool": "search_query",
            "status": "ok",
            "query": query,
            "search_type": search_type,
            "results": results,
        }
    except Exception as exc:  # server unreachable / HTTP error — degrade gracefully
        payload = {
            "tool": "search_query",
            "status": "unreachable",
            "error": str(exc),
            "request": {"query": query, "search_type": search_type, "limit": limit},
        }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
