#!/usr/bin/env python3
"""neoclaw_status — node liveness + identity probe: GET a node's `/health`, report up/down + which chip it
runs (chip_sha / mode / run count). A fast, PORTABLE (urllib only) liveness check — lighter than `discover`
(no catalog pull). Exits 0 iff the node is up; a down/unreachable node writes the report and exits non-zero.
"""
from __future__ import annotations
import json
import os
import sys
import urllib.error
import urllib.request


def main() -> int:
    # LOOK FOR THE GOVD: explicit NODE_URL, else $GOVD_URL (the configured node), else the local node — discover
    # the govd rather than demand a hardcoded address (the fleet node binds its tailnet IP, not loopback).
    node = (os.environ.get("NODE_URL") or os.environ.get("GOVD_URL") or "http://127.0.0.1:5773").rstrip("/")
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    out = os.path.join(store, "status.json")

    rec = {"tool": "neoclaw_status", "node": node, "up": False}
    try:
        with urllib.request.urlopen(node + "/health", timeout=6) as r:  # noqa: S310 (operator node URL)
            health = json.loads(r.read().decode())
        rec["up"] = True
        # include exec_mode/exod_attached — is this a govd+exod body (delegated) or a cooperative anchor?
        rec["health"] = {k: health.get(k) for k in
                         ("service", "mode", "chip_sha", "runs", "exec_mode", "exod_attached")}
    except (urllib.error.URLError, urllib.error.HTTPError, OSError, ValueError) as e:
        rec["error"] = str(e)

    with open(out, "w") as f:
        json.dump(rec, f, indent=2)
    print(json.dumps({"tool": "neoclaw_status", "up": rec["up"], "node": node,
                      "chip_sha": (rec.get("health") or {}).get("chip_sha")}))
    return 0 if rec["up"] else 1


if __name__ == "__main__":
    sys.exit(main())
