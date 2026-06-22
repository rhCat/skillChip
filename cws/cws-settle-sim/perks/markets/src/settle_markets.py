#!/usr/bin/env python3
"""settle_markets — SV-6 P6-T10 validator; runs the bounty + reverse-auction selftest, writes markets.json,
exits 0 iff ok (exactly one validated bounty winner with losers untouched; auction clears below posted)."""
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

from infra.settle import markets  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = markets.markets_selftest()
    with open(os.path.join(store, "markets.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_markets", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
