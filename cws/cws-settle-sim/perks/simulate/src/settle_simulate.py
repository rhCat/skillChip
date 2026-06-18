#!/usr/bin/env python3
"""settle_simulate — the cws-settle-sim authoring (P6-T18): storm + manipulate + dispute. Asserts the three
acceptance criteria on REAL runs — zero_sum_exact (10k-settlement storm), index_drift <2% @ 20% adversarial
(FMV), dispute_lifecycle_complete (bond -> m-of-n -> clawback). Writes simulate.json; exits 0 iff all three."""
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

from infra.settle import disputes, fmv, reward_ledger  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    storm = reward_ledger.reward_ledger_selftest(10_000)
    manip = fmv.fmv_selftest()
    disp = disputes.dispute_selftest()
    r = {"zero_sum_exact": storm["ok"] and storm["storm"]["global_zero"],
         "index_drift_under_2pct": manip["manipulation_bounded_under_2pct"],
         "dispute_lifecycle_complete": disp["ok"],
         "ok": (storm["ok"] and manip["manipulation_bounded_under_2pct"] and disp["ok"])}
    with open(os.path.join(store, "simulate.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_simulate", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
