#!/usr/bin/env python3
"""cws_checkpoint — the Merkle-checkpoint drill (P1-T03). Builds a checkpointed Ledger-v2 chain, cold-verifies
from the last checkpoint (window-bounded, under budget), and confirms a forged checkpoint is caught by the
deep audit. Writes checkpoint.json; exits 0 iff the drill holds."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "cwp")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.cwp import checkpoint  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    n = int(os.environ.get("N") or "20500")
    interval = int(os.environ.get("INTERVAL") or str(checkpoint.CHECKPOINT_INTERVAL))
    r = checkpoint.checkpoint_drill(n=n, interval=interval)
    with open(os.path.join(store, "checkpoint.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_checkpoint", "ok": r["ok"], "cold_verify_ms": r["cold_verify_ms"],
                      "cold_verify_tail": r["cold_verify_tail"], "within_budget": r["within_budget"],
                      "forged_checkpoint_detected": r["forged_checkpoint_detected"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
