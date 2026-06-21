#!/usr/bin/env python3
"""neoclaw_discover — discover a govd NODE: GET its `/health` + `/catalog` over HTTP, write discover.json.

This is the agent's read-only handle to a (possibly detached) govd node. It is deliberately PORTABLE — pure
`urllib`, no dependency on the local cyberware install — so any agent on any machine can point neoclaw at any
node by URL. It reports what the node governs (its catalog) and its identity (chip_sha / mode / run count).

Exits 0 iff the node is reachable AND returns its catalog (an honest "this node is operable" signal); a node
that is down / unreachable / forbidden still writes the report (for the audit ledger) and exits non-zero.
"""
from __future__ import annotations
import json
import os
import sys
import urllib.error
import urllib.request


def _get_json(url: str, timeout: int = 8):
    with urllib.request.urlopen(url, timeout=timeout) as r:  # noqa: S310 (operator-supplied node URL)
        return json.loads(r.read().decode())


def main() -> int:
    node = os.environ.get("NODE_URL", "").rstrip("/")
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    out = os.path.join(store, "discover.json")

    if not node:
        rec = {"tool": "neoclaw_discover", "ok": False, "error": "NODE_URL is required"}
        with open(out, "w") as f:
            json.dump(rec, f, indent=2)
        print(json.dumps(rec))
        return 2

    rec = {"tool": "neoclaw_discover", "node": node, "reachable": False, "ok": False}
    try:
        health = _get_json(node + "/health")
        rec["reachable"] = True
        rec["health"] = {k: health.get(k) for k in ("service", "mode", "chip_sha", "runs")}
        catalog = _get_json(node + "/catalog")
        skills = catalog.get("skills", [])
        rec["skills"] = sorted(s.get("skill") for s in skills if s.get("skill"))
        rec["skill_count"] = len(skills)
        rec["ok"] = bool(skills)
    except (urllib.error.URLError, urllib.error.HTTPError, OSError, ValueError) as e:
        rec["error"] = str(e)

    with open(out, "w") as f:
        json.dump(rec, f, indent=2)
    print(json.dumps({"tool": "neoclaw_discover", "ok": rec["ok"], "node": node,
                      "reachable": rec["reachable"], "skill_count": rec.get("skill_count", 0)}))
    return 0 if rec["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
