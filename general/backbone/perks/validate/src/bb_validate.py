#!/usr/bin/env python3
"""bb_validate — backbone layer 1: L++ schema/load validation of a blueprint.

Env: TARGET_BLUEPRINT (path to a lpp/v0.2.0 blueprint JSON), RECORD_STORE.
Output: ${RECORD_STORE}/backbone_validate.json — {"tool","blueprint","status","id","error"}.
Fail-closed: any load/validation error is status=fail and a nonzero exit.
"""
import json
import os
import sys


def validate_layer(path: str) -> dict:
    try:
        raw = json.load(open(path))
    except Exception as e:  # unreadable/invalid JSON is a validation failure, not a crash
        return {"status": "fail", "id": None, "error": f"unreadable JSON: {e}"}
    from lpp.core import load_blueprint
    bp, err = load_blueprint(raw)
    if err:
        return {"status": "fail", "id": raw.get("id"), "error": str(err)}
    return {"status": "ok", "id": raw.get("id"), "error": None}


def main() -> int:
    target = os.environ["TARGET_BLUEPRINT"]
    store = os.environ["RECORD_STORE"]
    os.makedirs(store, exist_ok=True)
    res = {"tool": "bb_validate", "blueprint": target, **validate_layer(target)}
    out = os.path.join(store, "backbone_validate.json")
    with open(out, "w") as f:
        json.dump(res, f, indent=1)
        f.write("\n")
    print(json.dumps({"tool": "bb_validate", "status": res["status"], "out": out}))
    return 0 if res["status"] == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
