#!/usr/bin/env python3
"""neoclaw_run — forward a governed CLAIM to a node and run it under the node's oversight.

The agent NAMES a sub-claim (a task-ledger: skill / perk / vars / record_store) and a NODE_URL; neoclaw submits
it to that node's govd through the governed run flow (`infra.govern.govd_client` / `run_governed`): the node
BLESSES the plan, GRANTS each step over its oversight channel, and the porters execute faithfully under the
node's non-root identity (the executor's no-root gate). neoclaw reports the node's VERDICT + a pointer to the
run's ledger — never the task data. A destructive sub-claim push_backs until APPROVE waives the named rule.

Unlike `discover` (pure urllib, portable), `run` drives the cyberware client (registry verification + the
per-step oversight handshake), so it needs the cyberware install + a registry matching the node's blessed chip.
"""
from __future__ import annotations
import json
import os
import subprocess
import sys


def _find_root(start):
    d = start
    while d != os.path.dirname(d):
        if os.path.isfile(os.path.join(d, "infra", "govern", "govd_client.py")):
            return d
        d = os.path.dirname(d)
    return None


def main() -> int:
    node = os.environ.get("NODE_URL", "").rstrip("/")
    sub = os.environ.get("SUB_LEDGER", "")
    approve = os.environ.get("APPROVE", "").split()
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    out = os.path.join(store, "run.json")

    def _emit(rec, code):
        with open(out, "w") as f:
            json.dump(rec, f, indent=2)
        print(json.dumps({"tool": "neoclaw_run", "ok": rec.get("ok", False),
                          "node": rec.get("node"), "target": rec.get("target"),
                          "decision": rec.get("decision"), "error": rec.get("error")}))
        return code

    if not node or not sub:
        return _emit({"tool": "neoclaw_run", "ok": False, "error": "NODE_URL and SUB_LEDGER are required"}, 2)
    if not os.path.isfile(sub):
        return _emit({"tool": "neoclaw_run", "ok": False, "error": f"SUB_LEDGER not found: {sub}"}, 2)

    root = os.environ.get("CYBERWARE_ROOT") or _find_root(os.path.dirname(os.path.abspath(__file__)))
    if not root:
        return _emit({"tool": "neoclaw_run", "ok": False,
                      "error": "cyberware install (infra/govern/govd_client.py) not found"}, 1)

    claim = json.load(open(sub))
    target = f"{claim.get('skill')}/{claim.get('perk')}"
    cmd = [sys.executable, "-m", "infra.govern.govd_client", "--url", node, "--ledger", sub]
    for rule in approve:
        cmd += ["--approve", rule]
    proc = subprocess.run(cmd, capture_output=True, text=True, env=dict(os.environ, PYTHONPATH=root))

    try:
        verdict = json.loads(proc.stdout.strip() or "{}")
    except ValueError:
        verdict = {}
    rec = {"tool": "neoclaw_run", "node": node, "target": target, "client_exit": proc.returncode,
           "decision": verdict.get("decision"), "plan_sha": verdict.get("plan_sha"),
           "ledger": verdict.get("ledger"), "verdict_error": verdict.get("error")}
    rec["ok"] = proc.returncode == 0 and verdict.get("decision") == "allow" and not verdict.get("error")
    if not rec["ok"]:
        rec["error"] = verdict.get("error") or (proc.stderr or proc.stdout)[-800:]
    return _emit(rec, 0 if rec["ok"] else 1)


if __name__ == "__main__":
    sys.exit(main())
