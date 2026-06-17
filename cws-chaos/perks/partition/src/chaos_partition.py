#!/usr/bin/env python3
"""chaos_partition — V-CHAOS drill; runs the hermetic fault-injection core, writes partition.json, exits 0 iff ok."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isfile(os.path.join(_d, "infra", "chaos.py")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra import chaos  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = chaos.partition_drill()
    with open(os.path.join(store, "partition.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "chaos_partition", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
