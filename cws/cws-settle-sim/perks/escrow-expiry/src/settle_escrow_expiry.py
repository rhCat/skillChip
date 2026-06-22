#!/usr/bin/env python3
"""settle_escrow_expiry — SV-6 P6-T03 validator; runs the escrow expiry/auto-refund selftest, writes
escrow_expiry.json, exits 0 iff ok (only expired-unsettled escrow refunds; no stale escrow after sweep;
globally zero-sum; idempotent)."""
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

from infra.settle import escrow_expiry  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = escrow_expiry.escrow_expiry_selftest()
    with open(os.path.join(store, "escrow_expiry.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_escrow_expiry", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
