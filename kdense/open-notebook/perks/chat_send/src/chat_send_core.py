#!/usr/bin/env python3
"""chat_send_core — POST /api/chat/execute via the vendored Open Notebook client.

Reads SESSION_ID, CHAT_MESSAGE, INCLUDE_SOURCES, INCLUDE_NOTES, and optional
MODEL_OVERRIDE from the environment, calls chat_interaction.send_chat_message,
and writes the AI response (or a graceful error payload when the server is
unreachable) as JSON to argv[1].
"""
import json
import os
import sys

import chat_interaction as ci


def _flag(name, default=True):
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in ("1", "true", "yes")


def main():
    out_path = sys.argv[1]
    session_id = os.getenv("SESSION_ID", "")
    message = os.getenv("CHAT_MESSAGE", "")
    model_override = os.getenv("MODEL_OVERRIDE", "").strip() or None
    try:
        result = ci.send_chat_message(
            session_id,
            message,
            include_sources=_flag("INCLUDE_SOURCES", True),
            include_notes=_flag("INCLUDE_NOTES", True),
            model_override=model_override,
        )
        payload = {"tool": "chat_send", "status": "ok", "result": result}
    except Exception as exc:  # server unreachable / HTTP error — degrade gracefully
        payload = {
            "tool": "chat_send",
            "status": "unreachable",
            "error": str(exc),
            "request": {"session_id": session_id, "message": message},
        }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
