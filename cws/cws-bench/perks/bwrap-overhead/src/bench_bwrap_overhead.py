#!/usr/bin/env python3
"""bench_bwrap_overhead — cws-bench perk: drive N benign steps through exod into the bwrap SandboxProfile,
read exod's OWN ATTESTED meter (P2-T07) for each, and assert the per-step overhead p95 is within the plan
budget (<= 100 ms). Exit 0 iff within budget. The meter is exod's, not the agent's stopwatch."""
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
    n = int(os.environ.get("N") or "30")
    b = bench.bench_bwrap(n=n)
    with open(os.path.join(store, "bench.json"), "w") as f:
        json.dump(b, f, indent=2)
    print(json.dumps(b))
    sys.exit(0 if b.get("within") is True else 1)


if __name__ == "__main__":
    main()
