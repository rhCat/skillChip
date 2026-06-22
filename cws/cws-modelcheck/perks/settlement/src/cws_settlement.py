#!/usr/bin/env python3
"""cws_settlement — P4-T06: model-check the settlement lifecycle (EMPIRICAL TLC + SYMBOLIC Apalache) and prove
each of the 3 money mutants (settle-before-validate / double-settle / strand-escrow) is caught. Writes
settlement.json; exits 0 iff ok. Needs the TLC + Apalache provers."""
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
    r = W.prove_settlement()
    with open(os.path.join(store, "settlement.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_settlement", "ok": r["ok"],
                      "empirical_plus_symbolic_pass": r["empirical_plus_symbolic_pass"],
                      "money_mutants_fail": r["money_mutants_fail"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
