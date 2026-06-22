#!/usr/bin/env python3
"""cws_bisimulation — P6-T07: prove the implemented settlement lifecycle is bisimilar to the committed
settlement.blueprint.json (every code transition maps to a blueprint transition and vice-versa), and a
seeded extra transition breaks it. Writes bisimulation.json; exits 0 iff ok. Pure (no prover stack)."""
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

from infra.cwp import workflow as W  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    bp = os.path.join(_root, "infra", "settle", "settlement.blueprint.json")
    r = W.prove_bisimulation(bp)
    with open(os.path.join(store, "bisimulation.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_bisimulation", "ok": r["ok"], "bisimilar": r["bisimilar"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
