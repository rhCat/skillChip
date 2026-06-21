#!/usr/bin/env python3
"""settle_credits — SV-6 settlement validator; runs the credit-billing hermetic core selftest, composes a
top-level `ok` (credits_selftest returns a flat bool dict with no `ok` of its own), writes credits.json,
exits 0 iff every check holds. Asserts credit-based usage billing: a top-up credits a prepaid balance, each
priced run DEBITS its usage tax as a zero-sum posting set, the balance draws down, a run whose tax EXCEEDS
the balance is REFUSED (the structural gate), and debits are idempotent per plan_sha."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "settle")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.settle import credits  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = credits.credits_selftest()
    r["ok"] = all(v for v in r.values() if isinstance(v, bool))
    with open(os.path.join(store, "credits.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_credits", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
