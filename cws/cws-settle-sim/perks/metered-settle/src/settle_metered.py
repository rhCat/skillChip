#!/usr/bin/env python3
"""settle_metered — P6-T08 (SV-6): exod-attested meters become settleable. Runs the hermetic core selftest,
writes metered.json, exits 0 iff ok."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "settle"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "settle")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.settle import metered  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = metered.metered_selftest()
    with open(os.path.join(store, "metered.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_metered", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
