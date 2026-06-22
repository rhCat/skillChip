#!/usr/bin/env python3
"""bench_org_isolation — P5-T03 validator: multi-tenant org isolation over principals. Proves tokens resolve
to their org with a SPIFFE id, revoked principals authenticate to none, per-org record roots are distinct,
and EVERY cross-org cell of the access matrix is refused. Writes org_isolation.json; exits 0 iff ok."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.govern import orgs  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = orgs.orgs_selftest()
    with open(os.path.join(store, "org_isolation.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "bench_org_isolation", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
