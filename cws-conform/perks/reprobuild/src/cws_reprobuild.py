#!/usr/bin/env python3
"""cws_reprobuild — reproducible engine build baseline (P0-T13). Builds the Go anchor twice with deterministic
flags in isolated caches (two independent builders) and asserts byte-identical digests; proves the diff is
empty (diffoscope where present, else the sha256 match is the proof); flips a byte to confirm the check
discriminates. Writes reprobuild.json; exits 0 iff identical + empty + tamper caught. Needs the go toolchain."""
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

from infra.cwp import reprobuild  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = reprobuild.reprobuild_selftest()
    with open(os.path.join(store, "reprobuild.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_reprobuild", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
