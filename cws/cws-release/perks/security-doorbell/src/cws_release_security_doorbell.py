#!/usr/bin/env python3
"""cws_release_security_doorbell — P3-T16 (M12 residue): the repo SECURITY.md is a real doorbell.

Checks the committed SECURITY.md names a CONTACT, an encrypted-reporting KEY/mechanism, and an
acknowledgement SLA. Writes doorbell.json; exits 0 iff all three are present."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.govern import doorbell  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = doorbell.doorbell_selftest(_root)
    with open(os.path.join(store, "doorbell.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_security_doorbell", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
