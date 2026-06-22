#!/usr/bin/env python3
"""bench_settle_throughput — P6-T16: settlement throughput of the single-writer-per-currency group-commit
path + checkpoint-resume, against P6-V17's budgets.

Drives N balanced posting sets through one GroupCommitWriter in batches (single writer per currency), then
checkpoints + resume-verifies. Measures: sustained tps, per-batch p95 latency, and resume-verify time.
Budgets (a REPRESENTATIVE measurement of the primitives, not the 10-min/1M production soak): tps >= 200,
per-batch p95 <= 250 ms, resume-verify <= 2000 ms. Writes throughput.json; exits 0 iff all three hold and
value is conserved.
"""
from __future__ import annotations
import json
import os
import sys
import time

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "settle"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "settle")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)
from infra.settle import reward_ledger as RL   # noqa: E402
from infra.settle import throughput as TP       # noqa: E402
from infra.settle.money import Money            # noqa: E402

N_SETS = int(os.environ.get("N_SETS") or "50000")
BATCH = int(os.environ.get("BATCH") or "1000")
TPS_FLOOR = 200.0
P95_CEIL_MS = 250.0
RESUME_CEIL_MS = 2000.0
CENT = Money("0.01", "USD")


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    out = os.path.join(store, "throughput.json")
    entries = RL.open_ledger("throughput-bench", "throughput-bench")
    w = TP.GroupCommitWriter(entries, "USD")

    lat = []
    t0 = time.perf_counter()
    for i in range(N_SETS):
        w.stage([RL._posting("pool", -CENT), RL._posting(f"payee{i % 64}", CENT)])
        if (i + 1) % BATCH == 0:
            c0 = time.perf_counter()
            w.commit()
            lat.append((time.perf_counter() - c0) * 1000.0)
    if w._staged:
        c0 = time.perf_counter()
        w.commit()
        lat.append((time.perf_counter() - c0) * 1000.0)
    elapsed = time.perf_counter() - t0
    tps = w.committed / elapsed if elapsed > 0 else 0.0
    lat.sort()
    p95_ms = lat[min(len(lat) - 1, int(len(lat) * 0.95))] if lat else 0.0

    cp = w.checkpoint()
    r0 = time.perf_counter()
    resumed = TP.resume_verify(cp)
    resume_ms = (time.perf_counter() - r0) * 1000.0
    conserved = RL.global_zero(entries)

    tps_ok = tps >= TPS_FLOOR
    p95_ok = p95_ms <= P95_CEIL_MS
    resume_ok = resumed and resume_ms <= RESUME_CEIL_MS
    within = tps_ok and p95_ok and resume_ok and conserved
    rep = {"perk": "settle-throughput", "n_sets": w.committed, "batch": BATCH, "accounts": len(cp["balances"]),
           "tps": round(tps, 1), "tps_floor": TPS_FLOOR, "tps_ok": tps_ok,
           "p95_ms": round(p95_ms, 2), "p95_ceil_ms": P95_CEIL_MS, "p95_ok": p95_ok,
           "resume_ms": round(resume_ms, 3), "resume_ceil_ms": RESUME_CEIL_MS, "resume_ok": resume_ok,
           "conserved": conserved, "within": within,
           "note": "representative measurement of the group-commit + O(accounts) resume primitives; the "
                   "10-min/1M-entry sustained soak is the production target"}
    json.dump(rep, open(out, "w"), indent=2)
    print(json.dumps({"tool": "bench_settle_throughput", "within": within, "tps": round(tps, 1),
                      "p95_ms": round(p95_ms, 2), "resume_ms": round(resume_ms, 3)}))
    return 0 if within else 1


if __name__ == "__main__":
    sys.exit(main())
