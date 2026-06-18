#!/usr/bin/env python3
"""cws_release_revoke — the signed revocation feed (P3-T03). A monotonic, publisher-signed {seq, expires,
revoked[]} feed: a revoked artifact is refused, a stale feed (>max-age) is feed_stale and fails closed, a
replayed older feed is rollback, a forged feed is bad_signature. Writes revoke.json; exits 0 iff every
property holds. Needs openssl (ed25519ph)."""
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

from infra.cwp import revocation  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = revocation.revocation_selftest()
    with open(os.path.join(store, "revoke.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_revoke", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
