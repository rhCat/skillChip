#!/usr/bin/env python3
"""fleet_down — stop + remove a deployed body container and DEREGISTER it from the roster.

The durable fleet-ledgers mirror is preserved (the governance domain is ephemeral; its provenance is not).
Emits down.json. Idempotent: a body already gone is still a success.
"""
from __future__ import annotations
import json
import os
import subprocess
import sys


def _run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def _deregister(fleet_file, name):
    """Remove the roster row by name, atomically (config write only — never the repo). No-op if the
    file/row is absent. Returns True iff a row was removed."""
    fleet_file = os.path.expanduser(fleet_file)
    if not os.path.isfile(fleet_file):
        return False
    try:
        data = json.load(open(fleet_file))
    except Exception:
        return False
    nodes = data.get("nodes") or []
    kept = [n for n in nodes if n.get("name") != name]
    if len(kept) == len(nodes):
        return False
    data["nodes"] = kept
    tmp = fleet_file + ".tmp"
    json.dump(data, open(tmp, "w"), indent=2)
    os.replace(tmp, fleet_file)
    return True


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    name = os.environ.get("NODE_NAME") or ""
    fleet_file = os.environ.get("FLEET_FILE") or "~/.cyberware/fleet.json"
    out = os.path.join(store, "down.json")
    log = open(os.path.join(store, "down.log"), "w")
    if not name:
        json.dump({"tool": "fleet_down", "status": "refused", "reason": "node_name_required"},
                  open(out, "w"), indent=2)
        print(json.dumps({"tool": "fleet_down", "status": "refused", "reason": "node_name_required"}))
        return 2
    for c in (["docker", "stop", name], ["docker", "rm", name]):   # no -f: oversight-clean, mirrors cws-deploy:down
        r = _run(c)
        log.write(r.stdout + r.stderr)
    gone = _run(["docker", "inspect", name]).returncode != 0       # absent (or no docker) -> gone
    deregistered = _deregister(fleet_file, name)
    rec = {"tool": "fleet_down", "status": "ok" if gone else "fail", "container": name,
           "removed": gone, "deregistered": deregistered,
           "note": "durable ledger mirror preserved", "log": os.path.join(store, "down.log")}
    json.dump(rec, open(out, "w"), indent=2)
    print(json.dumps(rec))
    return 0 if gone else 1


if __name__ == "__main__":
    sys.exit(main())
