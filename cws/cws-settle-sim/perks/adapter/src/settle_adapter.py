#!/usr/bin/env python3
"""settle_adapter — P6-T14 SettlementAdapter validator. Runs the hermetic adapter_selftest: the
SettlementAdapter interface + InternalCreditsAdapter zero-sum/idempotent fund+payout + a ledger↔sandbox
reconciliation exact to 0.0001 across 1k payouts + a 10k duplicate-delivery storm with 0 idempotency
violations + StripeAdapter inert-until-keyed. Writes adapter.json; exits 0 iff every check holds."""
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

from infra.settle import adapter  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = adapter.adapter_selftest()
    r["ok"] = all(v for v in r.values() if isinstance(v, bool))
    with open(os.path.join(store, "adapter.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_adapter", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
