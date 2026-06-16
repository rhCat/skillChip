#!/usr/bin/env python3
"""cws_schemas — CWP message-schema conformance (P0-T05). Validates the CWP instance corpus against the
2020-12 schemas under spec/schemas/: every valid instance must validate (100%) AND every negative instance
must be rejected. Writes schemas.json; exits 0 iff conformant."""
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

from infra.cwp import schemacheck  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    schemas_dir = os.environ.get("SCHEMAS_DIR") or schemacheck.DEFAULT_SCHEMAS
    r = schemacheck.check_corpus(schemas_dir)
    with open(os.path.join(store, "schemas.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "cws_schemas", "ok": r["ok"], "coverage": r["coverage"],
                      "valid": f"{r['valid_passed']}/{r['valid_total']}",
                      "invalid_rejected": f"{r['invalid_rejected']}/{r['invalid_total']}"}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
