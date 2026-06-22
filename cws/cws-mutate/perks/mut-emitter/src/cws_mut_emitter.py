#!/usr/bin/env python3
"""cws_chainverify — mutation-test a gate: mutate its source, run its test slice, score the survivors.

The enforcement-surface discipline of plan v1.1 §4 / R3 / V-MUT: *a gate that survives its own deletion
was never a gate.* This harness copies a project to a sandbox, applies one single-token mutation at a
time to the target file, runs the target's test slice, and counts a mutant KILLED when the slice fails
(nonzero exit) and SURVIVED when it passes. A survivor is a hole in the gate's coverage.

Reads from the (exported) environment:
  PROJECT_DIR   the project to copy into a sandbox (so the live tree is never touched)
  TARGET        the file WITHIN PROJECT_DIR to mutate (e.g. infra/govern/oversight.py)
  TEST_CMD      the test slice, run in the sandbox; NONZERO exit = the mutant was killed
  THRESHOLD     optional kill-score floor (default 0.90 — the plan's R3 bar)
  MAX_MUTANTS   optional cap on mutants generated (default 50)
  RECORD_STORE  where mutate.json + the audit line land

Writes RECORD_STORE/mutate.json and prints one structured JSON line. Exits 0 iff the baseline test
passes, at least one mutant was generated, and mutation_score >= THRESHOLD; nonzero otherwise (a weak or
absent gate, or a test slice that does not even pass on un-mutated code).
"""
from __future__ import annotations
import json
import os
import shutil
import subprocess
import sys
import tempfile

# Each pair maps a source token to its mutation. Spaces anchor operators so we never rewrite a substring
# of an identifier; the bare-word booleans are matched as whole tokens. One occurrence per mutant.
OPS = [
    (" == ", " != "), (" != ", " == "),
    (" < ", " >= "), (" > ", " <= "),
    (" <= ", " > "), (" >= ", " < "),
    (" and ", " or "), (" or ", " and "),
    (" + ", " - "), (" - ", " + "),
    ("True", "False"), ("False", "True"),
]


def mutants(src):
    """Yield (mutant_id, mutated_src) — one single-token mutation per yield."""
    for tok, rep in OPS:
        start = 0
        while True:
            i = src.find(tok, start)
            if i < 0:
                break
            yield f"{tok.strip()}->{rep.strip()}@{i}", src[:i] + rep + src[i + len(tok):]
            start = i + len(tok)


def run(cmd, cwd):
    # PYTHONDONTWRITEBYTECODE: a single-token mutation can preserve a source file's size, and CPython
    # keys a .pyc on (mtime-to-the-second, size) — so without this a mutant rewritten within the same
    # second as the baseline could load the ORIGINAL's cached bytecode and spuriously "survive".
    env = {**os.environ, "PYTHONDONTWRITEBYTECODE": "1"}
    try:
        return subprocess.run(cmd, shell=True, cwd=cwd, env=env,
                              capture_output=True, text=True, timeout=120).returncode
    except subprocess.TimeoutExpired:
        return 124   # a hung mutant counts as killed — it changed behavior enough to stall the slice


def main() -> int:
    pdir = os.environ["PROJECT_DIR"]
    # PINNED R3 gate (P1-T10): target + slice baked into this copied core (signed in the chip), so
    # the standing enforcement surface cannot be re-pointed by a caller; env overrides only for testing.
    target = os.environ.get("TARGET") or "infra/cwp/tla_emit.py"
    test_cmd = os.environ.get("TEST_CMD") or "python3 -m pytest tests/test_tla_emit.py -q -p no:cacheprovider"
    threshold = float(os.environ.get("THRESHOLD", "0.90"))
    cap = int(os.environ.get("MAX_MUTANTS", "50"))
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "mutate.json")
    os.makedirs(store, exist_ok=True)

    sandbox = tempfile.mkdtemp(prefix="cws-mutate-")
    try:
        proj = os.path.join(sandbox, "proj")
        shutil.copytree(pdir, proj)
        tpath = os.path.join(proj, target)
        if not os.path.isfile(tpath):
            report = {"target": target, "error": f"target not found in PROJECT_DIR: {target}",
                      "mutants": 0, "killed": 0, "survived": [], "mutation_score": 0.0}
            json.dump(report, open(out, "w"), indent=2)
            print(json.dumps({"tool": "cws_mut_emitter", "status": "error", "reason": "target_missing", "report": out}))
            return 1
        original = open(tpath).read()

        baseline = run(test_cmd, proj)                  # the slice MUST pass on un-mutated code, else score is meaningless
        if baseline != 0:
            report = {"target": target, "error": f"baseline test failed (exit {baseline}) — score undefined",
                      "mutants": 0, "killed": 0, "survived": [], "mutation_score": 0.0}
            json.dump(report, open(out, "w"), indent=2)
            print(json.dumps({"tool": "cws_mut_emitter", "status": "error", "reason": "baseline_failed", "report": out}))
            return 1

        survived, killed, total = [], 0, 0
        for mid, msrc in mutants(original):
            if total >= cap:
                break
            total += 1
            open(tpath, "w").write(msrc)
            if run(test_cmd, proj) != 0:
                killed += 1
            else:
                survived.append(mid)
            open(tpath, "w").write(original)            # restore before the next mutant

        score = round(killed / total, 4) if total else 0.0
        report = {"target": target, "test_cmd": test_cmd, "mutants": total, "killed": killed,
                  "survived": survived, "mutation_score": score, "threshold": threshold}
        json.dump(report, open(out, "w"), indent=2)
        ok = total > 0 and score >= threshold
        print(json.dumps({"tool": "cws_mut_emitter", "status": "ok" if ok else "weak", "mutants": total,
                          "killed": killed, "survived": len(survived), "score": score, "report": out}))
        return 0 if ok else 1
    finally:
        shutil.rmtree(sandbox, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
