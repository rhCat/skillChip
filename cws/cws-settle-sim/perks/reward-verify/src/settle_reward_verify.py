#!/usr/bin/env python3
"""settle_reward_verify — SV-6 P6-T06 validator; runs the money↔work cross-check selftest, writes
reward_verify.json, exits 0 iff ok (clean money↔work bijection + BOTH drift directions caught:
money_without_work and work_without_money)."""
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

from infra.settle import reward_verify  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = reward_verify.reward_verify_selftest()
    with open(os.path.join(store, "reward_verify.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_reward_verify", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
