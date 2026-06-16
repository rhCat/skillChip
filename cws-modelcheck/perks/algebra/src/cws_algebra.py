#!/usr/bin/env python3
"""cws_algebra — workflow algebra: seq/par compose into a finite product automaton within budget (P4-T03). Writes modelcheck.json; exits 0 iff the check passes. Needs the 3-prover stack."""
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
b = W.algebra_budget()
par_clean = W.check_tlc(W.compose(W.SAMPLE, W.SAGA, "par"))["verdict"] == "no_error"
ok = b["within_budget"] and b["finite"] and par_clean
rec = {"tool":"cws_algebra","ok":ok,"sizes":b["sizes"],"within_budget":b["within_budget"],"par_clean":par_clean}
store = os.environ["RECORD_STORE"].rstrip("/")
os.makedirs(store, exist_ok=True)
with open(os.path.join(store, "modelcheck.json"), "w") as f:
    json.dump(rec, f, indent=2)
print(json.dumps(rec))
sys.exit(0 if rec["ok"] else 1)
