#!/usr/bin/env python3
"""rt_govd_executor — P2-T12 red-team: govd-as-executor (server-side governed execution). Proves the agent's
claim carries zero secret bytes, govd runs the step server-side (the agent holds no limb) under a non-root
uid, the secret is resolved step-side yet only STATUS crosses back (no output, no secret), and the agent
environ stays clean. Writes govd_executor.json; exits 0 iff the boundary holds."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.govern import govd_executor  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = govd_executor.govd_executor_selftest()
    with open(os.path.join(store, "govd_executor.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "rt_govd_executor", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
