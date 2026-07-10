#!/usr/bin/env python3
"""bb_tlc — backbone layer 2: generate TLA+ from the blueprint and model-check with TLC.

Env: TARGET_BLUEPRINT, RECORD_STORE; optional TLC_TIMEOUT (seconds, default 120).
Output: ${RECORD_STORE}/backbone_tlc.json — {"tool","blueprint","status","detail","error"}.
Fail-closed: a missing `tlc` binary is status=fail (missing_tool), never a silent skip —
this perk is a gate, and a gate that cannot check refuses.
"""
import json
import os
import shutil
import sys


def tlc_layer(path: str, timeout: int) -> dict:
    if shutil.which("tlc") is None:
        return {"status": "fail", "detail": [], "error": "missing_tool: tlc not on PATH (fail-closed)"}
    try:
        bp = json.load(open(path))
    except Exception as e:
        return {"status": "fail", "detail": [], "error": f"unreadable JSON: {e}"}
    from lpp.core.validators.tla import validate_with_tlc
    ok, msg = validate_with_tlc(bp, timeout=timeout)
    tail = [l for l in msg.strip().splitlines() if l.strip()][-8:]
    return {"status": "ok" if ok else "fail", "detail": tail,
            "error": None if ok else "tlc_check_failed"}


def main() -> int:
    target = os.environ["TARGET_BLUEPRINT"]
    store = os.environ["RECORD_STORE"]
    timeout = int(os.environ.get("TLC_TIMEOUT", "120"))
    os.makedirs(store, exist_ok=True)
    res = {"tool": "bb_tlc", "blueprint": target, **tlc_layer(target, timeout)}
    out = os.path.join(store, "backbone_tlc.json")
    with open(out, "w") as f:
        json.dump(res, f, indent=1)
        f.write("\n")
    print(json.dumps({"tool": "bb_tlc", "status": res["status"], "out": out}))
    return 0 if res["status"] == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
