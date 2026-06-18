#!/usr/bin/env python3
"""rt_grant_replay — kernel red-team perk (channel family): mount the "grant-replay" attack THROUGH exod + the bwrap
SandboxProfile, with NO in-process software scan, and assert the SV-3 boundary REFUSED it — replay a spent capability grant — while
a benign-control ORACLE is still ACCEPTED. Exit 0 iff the boundary held. The behaviour is PINNED here."""
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

from infra.exec import redteam  # noqa: E402

ATTACK = "grant-replay"   # BAKED: this perk pins exactly this behaviour


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    out = redteam.run_attack(ATTACK)
    rec = {"tool": "rt_grant_replay", "attack": ATTACK, "family": out.family,
            "held": out.held, "refused": out.held, "detail": out.detail}
    with open(os.path.join(store, "redteam.json"), "w") as f:
        json.dump(rec, f, indent=2)
    print(json.dumps(rec))
    sys.exit(0 if out.held else 1)


if __name__ == "__main__":
    main()
