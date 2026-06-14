#!/usr/bin/env python3
"""rt_grant_forged - adversarial: tamper a signed grant claim; confirm the verifier REFUSES it offline (SV-3 spine)."""
from __future__ import annotations
import base64
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

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey  # noqa: E402
from infra.cwp import canonical  # noqa: E402
from infra.exec import grants  # noqa: E402

NOW = 1_000_000


def _report(out, perk, attack, boundary, clean_accepted, refused, refusal):
    held = clean_accepted and refused
    json.dump({"perk": perk, "attack": attack, "boundary": boundary,
               "clean_accepted": clean_accepted, "refused": refused, "refusal": refusal,
               "boundary_held": held}, open(out, "w"), indent=2)
    print(json.dumps({"tool": perk.replace("-", "_"), "status": "held" if held else "BREACH", "report": out}))
    return 0 if held else 1


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "redteam.json")
    os.makedirs(store, exist_ok=True)
    sk = Ed25519PrivateKey.generate()
    pk = sk.public_key()
    env = grants.mint_grant(sk, run_id="r", plan_sha="p", nbf=NOW - 10, exp=NOW + 100, nonce="f")
    clean_accepted = grants.verify_grant(pk, env, now=NOW)[0] is True
    body = json.loads(base64.b64decode(env["payload"]))
    body["capabilities"] = ["root"]                                     # escalate the claim, keep the old sig
    forged = {**env, "payload": base64.b64encode(canonical.canonical_bytes(body)).decode()}
    ok, reason = grants.verify_grant(pk, forged, now=NOW)
    refused = (ok is False) and reason == "bad_signature"
    return _report(out, "rt-grant-forged", "tamper a signed grant claim (privilege escalation)",
                   "infra.exec.grants.verify_grant DSSE signature (SV-3 spine)", clean_accepted, refused, reason)


if __name__ == "__main__":
    sys.exit(main())
