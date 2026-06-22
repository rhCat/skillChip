#!/usr/bin/env python3
"""rt_secret_isolation — P2-T05 red-team: the double-blind secret boundary. Proves the agent (cortex) holds
zero secret bytes during a credentialed run (the secret is injected step-side only), both backends satisfy one
get() contract, a leaked secret IS caught, and no *_FILE pointer is used. Writes secret_isolation.json; exits
0 iff the boundary holds."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "exec")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.exec import vault  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = vault.vault_selftest()
    with open(os.path.join(store, "secret_isolation.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "rt_secret_isolation", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
