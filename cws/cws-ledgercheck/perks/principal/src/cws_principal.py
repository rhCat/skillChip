#!/usr/bin/env python3
"""cws_principal — P1-T08 validator: govd's principal auth boundary. Runs the principals selftest proving a
missing/wrong Bearer is rejected (401), a burst is throttled (429), the token VALUE is never stored, and
EVERY provenance record carries its principal. Writes principal.json; exits 0 iff ok."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.govern import principals  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = principals.principals_selftest()
    with open(os.path.join(store, "principal.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_principal", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
