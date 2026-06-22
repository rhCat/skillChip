#!/usr/bin/env python3
"""settle_selfbounty — P6-T20 (SV-6, M12): cyberware's self-bounty security program. Runs the hermetic core
selftest, writes selfbounty.json, exits 0 iff ok."""
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

from infra.settle import selfbounty  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = selfbounty.selfbounty_selftest()
    with open(os.path.join(store, "selfbounty.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_selfbounty", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
