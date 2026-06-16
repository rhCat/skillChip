#!/usr/bin/env python3
"""cws_labeling — truth-in-labeling doc lint (P0-T16). Every enforcement claim in the specs (an "Enforced
by:" footer or an ENFORCED tag) must cite a plan criterion-id; a claim without one is a violation. Writes
labeling.json; exits 0 iff the convention is exercised and there are no violations."""
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

from infra.cwp import labeling  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    spec_dir = os.environ.get("SPEC_DIR") or labeling.DEFAULT_SPECS
    r = labeling.lint_specs(spec_dir)
    with open(os.path.join(store, "labeling.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_labeling", "ok": r["ok"], "docs": r["docs"], "claims": r["claims"],
                      "violations": len(r["violations"])}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
