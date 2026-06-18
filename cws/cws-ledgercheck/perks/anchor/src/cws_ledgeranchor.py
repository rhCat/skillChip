#!/usr/bin/env python3
"""cws_ledgeranchor — the external Go anchor for the Ledger-v2 cryptographic chain (P1-T04).

Builds the INDEPENDENT Go chain verifier (verifiers/go `chain`) and runs it over CHAIN_CORPUS, asserting it
reproduces infra/cwp/ledger.py verify_chain VERDICT-FOR-VERDICT: a sound chain (and the real CI done-ledger)
cold-verify; a single-bit tamper, a genesis transplant, a deleted-record seq gap, and a headless chain are
all detected — and a rejection must NAME the fault. Go and Python must agree on every chain; a divergence
fails the gate (meta-rule M3 / SV-2 — the point of a second, independently-written implementation). The
corpus must exercise both poles (≥1 sound, ≥1 caught) or it certifies nothing. Requires the `go` toolchain.

Reads CHAIN_CORPUS, RECORD_STORE from env; writes RECORD_STORE/anchor.json + one structured JSON line.
"""
from __future__ import annotations
import json
import os
import subprocess
import sys
import tempfile

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "cwp"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "cwp")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "cwp")):
    sys.path.insert(0, _root)

from infra.cwp import ledger as _ledger  # noqa: E402


def _fail(out, reason, detail=""):
    json.dump({"status": "fail", "match": False, "reason": reason, "detail": detail[-400:]}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_ledgeranchor", "status": "fail", "reason": reason, "report": out}))
    return 1


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "anchor.json")
    os.makedirs(store, exist_ok=True)
    go_dir = os.path.join(_root, "verifiers", "go")
    corpus = json.load(open(os.environ["CHAIN_CORPUS"]))

    binp = os.path.join(tempfile.mkdtemp(prefix="chain-"), "jcs")
    b = subprocess.run(["go", "build", "-o", binp, "."], cwd=go_dir, capture_output=True, text=True)
    if b.returncode != 0:
        return _fail(out, "go_build", b.stderr)
    run = subprocess.run([binp, "chain"], input=json.dumps(corpus), capture_output=True, text=True)
    if run.returncode != 0:
        return _fail(out, "go_run", run.stderr)
    go = {v["name"]: v for v in json.loads(run.stdout)}

    diffs, passed, caught = [], 0, 0
    for c in corpus:
        n = c["name"]
        py_ok, _py = _ledger.verify_chain(c["entries"], c.get("schema", 2),
                                          c.get("expect_run_id"), c.get("expect_plan_sha"))
        g = go.get(n, {})
        g_ok = g.get("ok")
        if g_ok != py_ok:                                    # the anchor: Go must match Python on every chain
            diffs.append(f"{n}: cross-language divergence go={g_ok} py={py_ok}")
            continue
        if "expect_ok" in c and g_ok != c["expect_ok"]:
            diffs.append(f"{n}: verdict {g_ok} != expected {c['expect_ok']}")
            continue
        if g_ok:
            passed += 1
        else:
            caught += 1
            if not g.get("problem"):                         # a rejection must name the offending record
                diffs.append(f"{n}: rejected but the fault is unnamed")
    if passed == 0:
        diffs.append("corpus certifies no sound chain — no discrimination")
    if caught == 0:
        diffs.append("corpus catches no corrupt chain — no discrimination")

    ok = not diffs
    report = {"status": "ok" if ok else "fail", "total": len(corpus), "go_cold_verified": passed,
              "go_caught": caught, "match": ok, "diffs": diffs[:20]}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_ledgeranchor", "status": report["status"], "total": len(corpus),
                      "diffs": len(diffs), "report": out}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
