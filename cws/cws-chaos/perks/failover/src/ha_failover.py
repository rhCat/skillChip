#!/usr/bin/env python3
"""ha_failover — P5-T04 validator: active-passive govd over a single-writer advisory-lock lease. Runs the
hermetic HA selftest (two in-process instances over ONE shared sqlite store, a deterministic clock — no live
Postgres, no sleeps) and writes failover.json; exits 0 iff all hold:

  * split_brain      — the lease is mutually exclusive; a partitioned second writer's shared-store appends are
                       gated (dropped + the attempt recorded), so the chain keeps a single writer.
  * failover_drill   — the active dies; past the TTL the standby acquires the lease and a re-sent step is
                       idempotent — ZERO duplicate grants, ZERO lost step_results.
  * no_orphaned_run  — after failover the interrupted run is intact on the artifact of record and the index
                       reconciles to zero divergence (resumable, not orphaned).
  * lease_lifecycle  — acquire / renew-keeps / expiry-handoff / fence-after-takeover / release.
"""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isfile(os.path.join(_d, "infra", "govern", "lease.py")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.govern import lease  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = lease.ha_selftest()
    with open(os.path.join(store, "failover.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "ha_failover", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
