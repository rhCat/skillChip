#!/usr/bin/env python3
"""bench_microvm_overhead — cws-bench perk: time a REAL microVM cold boot + a warm (snapshot) restore
through /dev/kvm and assert cold <= 1500 ms and warm <= 250 ms. Exit 0 iff BOTH budgets are met.

Where there is no /dev/kvm or no microVM backend, `bench.bench_microvm()` reports `skipped` (within:None)
and this porter exits nonzero — the budget is left HONESTLY unmet, never faked. So a clean pass can only
ever come from a host that actually booted a microVM under hardware virtualization."""
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

from infra.exec import bench  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    b = bench.bench_microvm()
    with open(os.path.join(store, "bench.json"), "w") as f:
        json.dump(b, f, indent=2)
    print(json.dumps(b))
    sys.exit(0 if b.get("within") is True else 1)


if __name__ == "__main__":
    main()
