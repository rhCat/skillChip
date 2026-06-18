#!/usr/bin/env python3
"""cws_release_citrinitas — the Citrinitas publish gate (P3-T09). Verified-tier admission requires alchemy
extract+conserve+classify+concord to be clean; a seeded conservation defect, an unnamed shape, and a
blueprint/CFG mismatch each BLOCK publish with the named reason; and chip-wide concord passes for every
modeled porter. Writes citrinitas.json; exits 0 iff the triple-block fires and chip-wide concord holds."""
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
    chip = os.path.join(_root, "skillChip")
    r = alchemy.gate_selftest(chip)
    with open(os.path.join(store, "citrinitas.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_citrinitas", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
