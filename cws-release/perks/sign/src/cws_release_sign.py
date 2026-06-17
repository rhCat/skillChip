#!/usr/bin/env python3
"""cws_release_sign — publisher signing for the release transparency layer (P3-T01). Signs the chip release
manifest (chip_sha + per-skill skill_shas) with the publisher key and proves the tri-layer refusal: an
unsigned/tampered release is rejected at chipfetch, govd boot AND exod run, against the PINNED TUF root.
Writes release.json; exits 0 iff signed passes + unsigned/tampered refused + root pinned. Needs openssl."""
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

from infra.cwp import release  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = release.release_selftest()
    with open(os.path.join(store, "release.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_sign", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
