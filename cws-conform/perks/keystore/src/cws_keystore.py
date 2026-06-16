#!/usr/bin/env python3
"""cws_keystore — the KeyStore seam contract (P0-T15). Runs both backends (FileKeyStore + SoftPkcs11KeyStore)
through one contract suite, confirms the seam is real (the file backend persists across instances) and the
PKCS#11 stub is non-exportable. Writes keystore.json; exits 0 iff both backends pass + the seam holds."""
import json
import os
import sys
import tempfile

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "cwp")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.cwp import keystore  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = keystore.keystore_drill(tempfile.mkdtemp(prefix="keystore-"))
    with open(os.path.join(store, "keystore.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_keystore", "ok": r["ok"], "both_backends_pass": r["both_backends_pass"],
                      "seam_real": r["seam_real"], "hsm_key_nonexportable": r["hsm_key_nonexportable"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
