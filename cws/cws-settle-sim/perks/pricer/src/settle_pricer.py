#!/usr/bin/env python3
"""settle_pricer — SV-6 settlement validator; runs the plan-pricer hermetic core selftest, composes a
top-level `ok` (price_selftest returns a flat bool dict with no `ok` of its own), writes pricer.json, exits
0 iff every check holds. Asserts the value-free PLAN prices BEFORE it runs: the itemized subtotal and the
total sum EXACTLY (Money, scale-4), a seeded tool_fee flows into the total, freeform pricing differs from
contract pricing, and infra/settle stays float-clean."""
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

from infra.settle import price  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = price.price_selftest()
    r["ok"] = all(v for v in r.values() if isinstance(v, bool))
    with open(os.path.join(store, "pricer.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_pricer", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
