#!/usr/bin/env python3
"""rt_ungoverned_banner — kernel red-team perk (honesty family): the legacy in-process path must announce
itself [UNGOVERNED-BOUNDARY] on EVERY run and tag its result ungoverned, so it can never masquerade as a
governed (exod-signed) step-result (P2-T11). Exit 0 iff the boundary held (banner every run + honest
governed/ungoverned distinction). Pure logic."""
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

ATTACK = "ungoverned-banner"   # BAKED


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    out = redteam.run_attack(ATTACK)
    rec = {"tool": "rt_ungoverned_banner", "attack": ATTACK, "family": out.family,
           "held": out.held, "refused": out.held, "detail": out.detail}
    with open(os.path.join(store, "redteam.json"), "w") as f:
        json.dump(rec, f, indent=2)
    print(json.dumps(rec))
    sys.exit(0 if out.held else 1)


if __name__ == "__main__":
    main()
