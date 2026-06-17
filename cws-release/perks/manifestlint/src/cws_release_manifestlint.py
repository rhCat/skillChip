#!/usr/bin/env python3
"""cws_release_manifestlint — publish-time manifest lint (P3-T10). What a perk actually does must match what
it declares; the lint catches 100% of three drift classes — undeclared binary, undeclared egress, capability
mismatch. Writes manifestlint.json; exits 0 iff the clean perk passes and all seeded defects are caught."""
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

from infra.cwp import manifestlint  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = manifestlint.manifest_selftest()
    with open(os.path.join(store, "manifestlint.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_manifestlint", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
