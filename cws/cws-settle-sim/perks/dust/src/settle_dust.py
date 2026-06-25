#!/usr/bin/env python3
"""settle_dust — P6-T15 validator: the adapter-boundary rounding rule + the dust account. Runs the hermetic
dust_selftest: banker's rounding (scale-4 <-> integer cents), the sub-cent residue posts to dust:adapter:<id>
inside the SAME balanced entry, a 100k FX-boundary storm stays globally zero-sum INCLUDING dust, and the
monthly sweep is balanced + Ed25519-signed (a tampered sweep is caught). Writes dust.json; exits 0 iff all hold."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "settle")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.settle import dust  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = dust.dust_selftest()
    r["ok"] = all(v for v in r.values() if isinstance(v, bool))
    with open(os.path.join(store, "dust.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_dust", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
