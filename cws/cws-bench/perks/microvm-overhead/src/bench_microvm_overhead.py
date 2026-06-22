#!/usr/bin/env python3
"""bench_microvm_overhead — cws-bench perk: time a REAL microVM cold boot + a warm (snapshot) restore
through /dev/kvm and assert cold <= 1500 ms and warm <= 250 ms. Exit 0 iff BOTH budgets are met.

Where there is no /dev/kvm or no microVM backend, `bench.bench_microvm()` reports `skipped` (within:None)
and this porter exits nonzero — the budget is left HONESTLY unmet, never faked. So a clean pass can only
ever come from a host that actually booted a microVM under hardware virtualization."""
import json
import os
import signal
import sys
import traceback

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "cwp")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.exec import bench  # noqa: E402

HARD_CAP_S = 240            # a real boot+snapshot is ~seconds; never let a wedged backend hang the run


def _cap(_sig, _frame):
    raise TimeoutError(f"microvm bench exceeded its {HARD_CAP_S}s hard cap (boot / API / snapshot wedged)")


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    if hasattr(signal, "SIGALRM"):
        signal.signal(signal.SIGALRM, _cap)
        signal.alarm(HARD_CAP_S)
    try:
        b = bench.bench_microvm()
    except BaseException as e:                          # incl. TimeoutError / boot failure — capture, never hang
        b = {"backend": "microvm", "within": False, "error": f"{type(e).__name__}: {e}",
             "traceback": traceback.format_exc()[-1500:]}
    finally:
        if hasattr(signal, "SIGALRM"):
            signal.alarm(0)
    with open(os.path.join(store, "bench.json"), "w") as f:        # always written -> uploaded as evidence
        json.dump(b, f, indent=2)
    print(json.dumps(b))
    sys.exit(0 if b.get("within") is True else 1)


if __name__ == "__main__":
    main()
