#!/usr/bin/env python3
"""settle_rail — SV-6 settlement validator; runs the tax-rail hermetic core selftest, composes a top-level
`ok` (rails_selftest returns a flat bool dict with no `ok` of its own), writes rail.json, exits 0 iff every
check holds. Asserts the platform tax is collected at SETTLE (not an agent action, not a hidden portal): the
charge splits into VISIBLE substrate/author/marketplace lines that re-sum to the total, an over-total split
is REFUSED (no skim), StripeRail stays inert until keyed, and collect_run_tax settles zero-sum + idempotent
per plan_sha."""
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

from infra.settle import rails  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    r = rails.rails_selftest()
    r["ok"] = all(v for v in r.values() if isinstance(v, bool))
    with open(os.path.join(store, "rail.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_rail", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
