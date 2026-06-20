#!/usr/bin/env python3
"""chat_session_create_core — POST /api/chat/sessions via the vendored client.

Reads NOTEBOOK_ID, SESSION_TITLE, and optional MODEL_OVERRIDE from the
environment, calls chat_interaction.create_chat_session, and writes the created
session (or a graceful error payload when the server is unreachable) as JSON to
argv[1].
"""
import json
import os
import sys

import chat_interaction as ci


def main():
    out_path = sys.argv[1]
    notebook_id = os.getenv("NOTEBOOK_ID", "")
    title = os.getenv("SESSION_TITLE", "Chat session")
    model_override = os.getenv("MODEL_OVERRIDE", "").strip() or None
    try:
        session = ci.create_chat_session(notebook_id, title, model_override=model_override)
        payload = {"tool": "chat_session_create", "status": "ok", "session": session}
    except Exception as exc:  # server unreachable / HTTP error — degrade gracefully
        payload = {
            "tool": "chat_session_create",
            "status": "unreachable",
            "error": str(exc),
            "request": {"notebook_id": notebook_id, "title": title},
        }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
