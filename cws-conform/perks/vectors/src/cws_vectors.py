#!/usr/bin/env python3
"""cws_vectors — replay the golden vector corpus through the canonical-bytes + signing path (P0-V0x).

Produces the governed conformance verdict the SV-1 rung turns on (P0-T07 corpus + P0-T17 verdict):
every canonicalization vector must canonicalize + digest without error, every signature vector's DSSE
verdict must match its declared expectation, and the corpus must cover the required categories. Emits
conformance.json {total, failed, covers, ...}; passes iff failed == 0 and total >= MIN_TOTAL (250).

Reads CORPUS (+ optional SIG_CORPUS), MIN_TOTAL (default 250), RECORD_STORE from env.
"""
from __future__ import annotations
import base64
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra.cwp import canonical  # noqa: E402

# vector-name prefix → the plan's P0-T07 coverage category
CATS = [("ctrl_", "unicode"), ("str_", "unicode"), ("sort_", "unicode"),
        ("flt_", "number-format"), ("sweep_", "number-format"), ("int_", "number-format"), ("rfc", "number-format"),
        ("nest_", "nesting"), ("lit_", "digests"), ("rec_", "digests"), ("chip_", "chip"), ("sig_", "signatures")]


def _cover(name):
    for p, c in CATS:
        if name.startswith(p):
            return c
    return "other"


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "conformance.json")
    os.makedirs(store, exist_ok=True)
    min_total = int(os.environ.get("MIN_TOTAL", "250"))
    corpus = json.load(open(os.environ["CORPUS"]))
    sig_corpus = json.load(open(os.environ["SIG_CORPUS"])) if os.environ.get("SIG_CORPUS") else []

    covers, failed, sig_ok = set(), [], 0
    for vec in corpus:
        covers.add(_cover(vec["name"]))
        try:
            canonical.canonicalize(vec["input"])
            canonical.digest(vec["input"])
        except Exception as e:                                # a vector that won't canonicalize is a conformance failure
            failed.append({"name": vec["name"], "err": str(e)})
    if sig_corpus:
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
        from infra.cwp import sign
        for vec in sig_corpus:
            covers.add("signatures")
            pub = Ed25519PublicKey.from_public_bytes(base64.b64decode(vec["pubkey"]))
            if sign.verify(vec["envelope"], pub) == vec["expect_valid"]:
                sig_ok += 1
            else:
                failed.append({"name": vec["name"], "err": "sig verdict mismatch"})

    total = len(corpus) + len(sig_corpus)
    ok = len(failed) == 0 and total >= min_total
    report = {"status": "ok" if ok else "fail", "total": total, "canonical_vectors": len(corpus),
              "sig_vectors": len(sig_corpus), "sig_ok": sig_ok, "failed": len(failed),
              "failures": failed[:10], "covers": sorted(covers), "min_total": min_total}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_vectors", "total": total, "failed": len(failed),
                      "covers": sorted(covers), "status": report["status"], "report": out}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
