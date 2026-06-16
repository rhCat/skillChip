#!/usr/bin/env python3
"""cws_saga — failure-as-transitions + saga compensation, model AND execution (P4-T02). Writes modelcheck.json; exits 0 iff the check passes. Needs the 3-prover stack."""
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
good = W.check_tlc(W.SAGA)["verdict"] == "no_error"
caught = W.check_tlc(W.buggy_saga())["verdict"] == "violation"
comp = W.run_saga(3, fail_at=1)["compensation_ran"]
ok = good and caught and comp
rec = {"tool":"cws_saga","ok":ok,"model_good":good,"buggy_caught":caught,"compensation_ran":comp}
store = os.environ["RECORD_STORE"].rstrip("/")
os.makedirs(store, exist_ok=True)
with open(os.path.join(store, "modelcheck.json"), "w") as f:
    json.dump(rec, f, indent=2)
print(json.dumps(rec))
sys.exit(0 if rec["ok"] else 1)
