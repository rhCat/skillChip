#!/usr/bin/env python3
"""settle_engine — SV-6 settlement validator; runs the hermetic Python core selftest, writes settle.json, exits 0 iff ok."""
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

from infra.settle import engine  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = engine.engine_selftest()
    with open(os.path.join(store, "settle.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_engine", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
