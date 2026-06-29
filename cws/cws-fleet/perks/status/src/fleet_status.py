#!/usr/bin/env python3
"""fleet_status — read-only fleet overview: the roster + each body's container state + /health.

Value-free (node metadata only — no secrets, no tokens). Tolerates an absent docker daemon and unreachable
nodes (a read-only view must never fail closed). Emits status.json.
"""
from __future__ import annotations
import json
import os
import subprocess
import sys
import urllib.request


def _docker_state(name):
    if not name:
        return "absent"
    try:
        r = subprocess.run(["docker", "inspect", "-f", "{{.State.Status}}", name],
                           capture_output=True, text=True, timeout=5)
        return r.stdout.strip() if r.returncode == 0 else "absent"
    except Exception:
        return "absent"      # no docker binary/daemon -> a read-only view stays green


def _health(url):
    if not url:
        return None
    try:
        with urllib.request.urlopen(url.rstrip("/") + "/health", timeout=3) as r:
            h = json.loads(r.read())
        return {"status": h.get("status"), "chip_sha": h.get("chip_sha"),
                "exec_mode": h.get("exec_mode"), "exod_attached": h.get("exod_attached"),
                "runs": h.get("runs")}
    except Exception:
        return None


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    fleet_file = os.path.expanduser(os.environ.get("FLEET_FILE") or "~/.cyberware/fleet.json")
    out = os.path.join(store, "status.json")
    nodes = []
    if os.path.isfile(fleet_file):
        try:
            nodes = json.load(open(fleet_file)).get("nodes") or []
        except Exception:
            nodes = []
    rows = []
    for n in nodes:
        rows.append({"name": n.get("name"), "role": n.get("role"), "tier": n.get("tier"),
                     "fleet_tier": n.get("fleet_tier"), "url": n.get("url"),
                     "container": _docker_state(n.get("name")), "health": _health(n.get("url"))})
    json.dump({"tool": "fleet_status", "status": "ok", "fleet_file": fleet_file,
               "node_count": len(rows), "nodes": rows}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "fleet_status", "status": "ok", "node_count": len(rows), "out": out}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
