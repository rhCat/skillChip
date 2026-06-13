#!/usr/bin/env python3
"""cws_check — check a blueprint/workflow for abstract deadlock: structural + EMPIRICAL (TLC).

Composes `infra/govern/composer`: the pure-Python structural check (non-terminal sinks, reachability
from entry, a reachable terminal) always runs; when a JRE + `TLA2TOOLS_JAR` are present, TLC adds the
EMPIRICAL certificate over the emitted TLA+. A blueprint passes iff it has no structural issue and TLC
did not find an error (TLC absent => the structural check stands alone, recorded honestly as `skipped`).

Reads TARGET_BLUEPRINT + RECORD_STORE from env; writes RECORD_STORE/modelcheck.json + one structured
JSON line. Exit 0 iff status == ok.
"""
from __future__ import annotations
import json
import os
import sys

# Locate the cyberware repo root (the dir holding infra/govern): prefer CYBERWARE_ROOT (needed when the
# chip is vendored outside the tree, e.g. CLOUD_MODE), else ascend from this file (in-tree submodule).
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra.govern import composer  # noqa: E402


def check_blueprint(bp):
    issues = composer.structural(bp)
    ok, msg, _ = composer.run_tlc(composer.emit_tla(bp), "task")
    empirical = "no_error" if ok else ("skipped" if ok is None else "error")
    status = "ok" if (not issues and ok is not False) else "fail"
    return {"structural": issues, "empirical": empirical, "tlc_msg": msg, "status": status}


def main() -> int:
    target = os.environ["TARGET_BLUEPRINT"]
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "modelcheck.json")
    os.makedirs(store, exist_ok=True)
    bp = json.load(open(target))
    cert = check_blueprint(bp)
    cert["target"] = target
    cert["states"] = len(bp.get("states", {}))
    cert["transitions"] = len(bp.get("transitions", []))
    json.dump(cert, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_check", "status": cert["status"], "empirical": cert["empirical"],
                      "structural_issues": len(cert["structural"]), "report": out}))
    return 0 if cert["status"] == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
