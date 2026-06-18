#!/usr/bin/env python3
"""cws_release_approval — WebAuthn approval for destructive grants (P3-T04). The challenge is sha256(JCS(doc)),
so an approval is bound to one canonical doc; verification is fully offline from the stored assertion + COSE
key. A different doc, a flipped signature, a cleared UV bit, or a wrong origin are refused; a destructive grant
without a verified approval does not proceed. Writes approval.json; exits 0 iff every property holds."""
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

from infra.cwp import webauthn  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = webauthn.webauthn_selftest()
    with open(os.path.join(store, "approval.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_approval", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
