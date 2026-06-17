#!/usr/bin/env python3
"""alchemy_extract — alchemy extract verb (P3-T08). Runs the REAL pinned engine on a hermetic fixture and asserts the
acceptance metric (no stub). Writes extract.json; exits 0 iff ok."""
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

from infra.cwp import alchemy  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = alchemy.extract_selftest()
    with open(os.path.join(store, "extract.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "alchemy_extract", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
