#!/usr/bin/env python3
"""cws_release_transparency — offline transparency proofs for releases (P3-T02). Builds a Merkle log of
release envelopes, emits a self-contained inclusion proof + publisher-signed tree head, and verifies it
OFFLINE against the pinned root (no live Rekor). Confirms the refusals: unsigned/forged head, tampered leaf,
wrong index. Writes transparency.json; exits 0 iff valid verifies + every refusal fires + root pinned."""
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

from infra.cwp import translog  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = translog.transparency_selftest()
    with open(os.path.join(store, "transparency.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_transparency", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
