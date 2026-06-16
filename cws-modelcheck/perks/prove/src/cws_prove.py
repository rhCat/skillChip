#!/usr/bin/env python3
"""cws_prove — check workflow safety with all 3 provers (P4-T01/T04/T05/T08): corpus dual-check + 3 certs. Writes modelcheck.json; exits 0 iff the check passes. Needs the 3-prover stack."""
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
corpus = W.run_corpus(); c = W.certs()
ok = corpus["ok"] and c["have_all_three"]
rec = {"tool":"cws_prove","ok":ok,"corpus_ok":corpus["ok"],"tlc":"%d/%d"%(corpus["tlc_correct"],corpus["total"]),"apalache":"%d/%d"%(corpus["apalache_correct"],corpus["total"]),"disagreements":corpus["disagreements"],"certs":c["certs"]}
store = os.environ["RECORD_STORE"].rstrip("/")
os.makedirs(store, exist_ok=True)
with open(os.path.join(store, "modelcheck.json"), "w") as f:
    json.dump(rec, f, indent=2)
print(json.dumps(rec))
sys.exit(0 if rec["ok"] else 1)
