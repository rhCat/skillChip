#!/usr/bin/env python3
"""cws_release_engine — engine attestation + mutual handshake (P3-T05). Publisher-signs the engine's
reproducible-build digest; runs a mutual handshake between two principals and confirms a one-byte tamper on
either side yields engine_unattested; binds a dual-signed release receipt so the live engine's health matches
the signed release. Writes engine.json; exits 0 iff the clean handshake attests, both tampers fail closed,
and health matches. Needs openssl (ed25519ph)."""
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

from infra.cwp import engineattest  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = engineattest.engine_selftest()
    with open(os.path.join(store, "engine.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_release_engine", **r}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
