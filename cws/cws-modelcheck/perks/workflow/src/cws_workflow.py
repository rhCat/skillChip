#!/usr/bin/env python3
"""cws_workflow — the plan verifies the plan — the engine pipeline as a deadlock-free workflow (P4-T09). Writes modelcheck.json; exits 0 iff the check passes. Needs the 3-prover stack."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "cwp")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.cwp import workflow as W
v = W.check_tlc(W.plan_workflow())["verdict"]
ok = v == "no_error"
rec = {"tool":"cws_workflow","ok":ok,"verdict":v}
store = os.environ["RECORD_STORE"].rstrip("/")
os.makedirs(store, exist_ok=True)
with open(os.path.join(store, "modelcheck.json"), "w") as f:
    json.dump(rec, f, indent=2)
print(json.dumps(rec))
sys.exit(0 if rec["ok"] else 1)
