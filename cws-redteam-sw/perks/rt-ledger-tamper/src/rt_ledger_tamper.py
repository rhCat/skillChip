#!/usr/bin/env python3
"""rt_ledger_tamper — adversarial: tamper a Ledger-v2 record; confirm the chain verifier REFUSES it.

Software-tier red-team (SV-1/SV-2, NOT the SV-3 kernel boundary). A sound chain must be accepted (the
oracle — so this goes RED if the verifier goes silently no-op) AND a single-field tamper must be refused.
A recorded refusal is the evidence (meta-rule M4). Exit 0 iff the boundary held."""
from __future__ import annotations
import copy
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "cwp"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "cwp")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "cwp")):
    sys.path.insert(0, _root)

from infra.cwp import ledger as L  # noqa: E402


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "redteam.json")
    os.makedirs(store, exist_ok=True)
    chain = [L.genesis("run-rt", "plan-rt")]
    L.append(chain, {"task_id": "t1", "verdict": "pass"})
    L.append(chain, {"task_id": "t2", "verdict": "pass"})
    clean_accepted = L.verify_chain(chain, 2)[0] is True
    tampered = copy.deepcopy(chain)
    tampered[1] = {**tampered[1], "task_id": "EVIL"}
    ok, problems = L.verify_chain(tampered, 2)
    refused = ok is False
    held = clean_accepted and refused
    json.dump({"perk": "rt-ledger-tamper", "attack": "single-field tamper of a Ledger-v2 record",
               "boundary": "infra.cwp.chainverify.verify_chain (SV-2 software boundary)",
               "clean_accepted": clean_accepted, "refused": refused,
               "refusal": problems[0] if problems else None, "boundary_held": held}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "rt_ledger_tamper", "status": "held" if held else "BREACH", "report": out}))
    return 0 if held else 1


if __name__ == "__main__":
    sys.exit(main())
