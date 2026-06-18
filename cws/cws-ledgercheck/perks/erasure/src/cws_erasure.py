#!/usr/bin/env python3
"""cws_erasure — the crypto-shredding erasure drill (P1-T07). Builds a Ledger-v2 chain over per-record
sealed subject fields, destroys one record's DEK, and asserts: the chain still verifies, the shredded
record's subject fields are unrecoverable, and every other record is unaffected. Writes erasure.json;
exits 0 iff the drill holds."""
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

from infra.cwp import shred  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    n = int(os.environ.get("N") or "5")
    k = int(os.environ.get("SHRED_INDEX") or "2")
    r = shred.erasure_drill(n=n, shred_index=k)
    with open(os.path.join(store, "erasure.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_erasure", "ok": r["ok"],
                      "chain_verifies_after_shred": r["chain_verifies_after_shred"],
                      "shredded_unrecoverable": r["shredded_unrecoverable"],
                      "others_recoverable": r["others_recoverable"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
