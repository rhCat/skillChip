#!/usr/bin/env python3
"""settle_reputation — SV-6 P6-T13 validator; runs the reputation selftest, writes reputation.json, exits 0
iff ok (third-party reproducible from public ledger + signed + privacy-gated /rep view)."""
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

from infra.settle import reputation  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = reputation.reputation_selftest()
    with open(os.path.join(store, "reputation.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_reputation", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
