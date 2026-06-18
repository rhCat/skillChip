#!/usr/bin/env python3
"""cws_release_publish — the governed release receipt (P3-T15). Composes the chip release (P3-T01), the
engine attestation (P3-T05) and the offline transparency proof (P3-T02) into ONE dual-signed, transparency-
logged receipt and verifies it end to end offline; tampering any single leg fails it closed. Writes
publish.json; exits 0 iff the governed release verifies, the rekor proof is stored, and every leg tamper is
caught. Needs openssl (ed25519ph)."""
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

from infra.cwp import publish  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = publish.publish_selftest()
    with open(os.path.join(store, "publish.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_publish", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
