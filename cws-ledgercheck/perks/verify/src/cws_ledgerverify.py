#!/usr/bin/env python3
"""cws_ledgerverify — verify a ledger is a sound provenance chain. Two shapes, the right check for each:

  * Ledger-v2 CRYPTOGRAPHIC chain (P1-T01) — a JSONL file (one record per line), a JSON list, or a
    {schema, entries:[…]} object whose records carry `prev`/`seq`. Each record's `prev` is RECOMPUTED as
    the prior link's digest under the chain's schema major (infra.cwp.ledger.verify_chain — the RFC-8785
    JCS form the Go anchor reproduces). A tampered field or a transplanted genesis (the chain replayed
    under a different {run_id, plan_sha}, which the genesis link covers) breaks the recompute and the
    offending record is NAMED. This is the SV-2 property: evidence is independently re-verifiable, not
    merely trusted.

  * executor RUN-LEDGER (structural) — the {script, runs:[…]} format written by infra/govern/executor.py:
    structure, step provenance (exit + stdout_sha), recorded refusals as evidence (meta-rule M4), and a
    contiguous 1..N ordering. (The cryptographic chain above is the durable provenance; this is the
    per-run execution log.)

Reads TARGET_LEDGER + RECORD_STORE from env; writes RECORD_STORE/ledgercheck.json + one structured JSON
line. Exit 0 iff the ledger is sound, nonzero otherwise.
"""
from __future__ import annotations
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "cwp"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "cwp")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "cwp")):
    sys.path.insert(0, _root)

from infra.cwp import ledger as _ledger  # noqa: E402

EVENT_KINDS = {"tamper_refused", "oversight_refused", "oversight_waived"}


def _is_chain(ledger):
    """A Ledger-v2 cryptographic chain: a list of records, or a {entries:[…]} object that is NOT the
    executor's structural run-ledger ({script, runs})."""
    if isinstance(ledger, list):
        return True
    return isinstance(ledger, dict) and "entries" in ledger and "runs" not in ledger


def verify_structural(ledger):
    """Return (records, bad) for the executor's structural run-ledger ({script, runs})."""
    if not isinstance(ledger, dict):
        return 0, ["ledger is not a JSON object"]
    bad = []
    if not isinstance(ledger.get("script"), str):
        bad.append("missing or non-string 'script'")
    runs = ledger.get("runs")
    if not isinstance(runs, list):
        return 0, bad + ["missing or non-list 'runs'"]
    ok_steps = []
    for i, r in enumerate(runs):
        if not isinstance(r, dict):
            bad.append(f"run[{i}] is not an object")
            continue
        if not r.get("ts"):
            bad.append(f"run[{i}] missing 'ts'")
        if "event" in r:
            if r["event"] not in EVENT_KINDS:
                bad.append(f"run[{i}] unknown event {r['event']!r}")
            continue
        step = r.get("step")
        if step is None:
            bad.append(f"run[{i}] has neither 'event' nor 'step'")
            continue
        if r.get("status") == "ok":
            if "exit" not in r or "stdout_sha" not in r:
                bad.append(f"run[{i}] (step {step}) is ok but missing exit/stdout_sha")
            if str(step).isdigit():
                n = int(step)
                if n < 1:                                   # the compiler numbers steps from 1; 0/negative is malformed
                    bad.append(f"run[{i}] ok step '{step}' is below 1 (steps are 1-based)")
                else:
                    ok_steps.append(n)
    if ok_steps:                                    # ordering: ok steps must be a contiguous prefix 1..N
        hi = max(ok_steps)
        present = set(ok_steps)
        gaps = [s for s in range(1, hi + 1) if s not in present]
        if gaps:
            bad.append(f"ordering gap — step(s) {gaps} never recorded ok below step {hi} (out-of-band run?)")
    return len(runs), bad


def verify(ledger, schema=None, expect_run_id=None, expect_plan_sha=None, allow_legacy=False):
    """Dispatch by shape. Returns (records, bad, mode); empty `bad` means the ledger is sound.

    A Ledger-v2 chain is re-verified cryptographically (infra.cwp.ledger.verify_chain). The chain may not
    pick its own algorithm: a chain declaring a legacy schema (< CURRENT_MAJOR) is REFUSED unless the
    operator opts in via allow_legacy, so a forged schema-downgrade can't be verified under the retired
    digest. expect_run_id / expect_plan_sha (out-of-band) certify non-transplant when supplied."""
    if _is_chain(ledger):
        entries = ledger if isinstance(ledger, list) else ledger.get("entries", [])
        head = entries[0] if entries and isinstance(entries[0], dict) else {}
        sch = schema or (ledger.get("schema") if isinstance(ledger, dict) else None) \
            or head.get("schema") or _ledger.CURRENT_MAJOR
        if sch != _ledger.CURRENT_MAJOR and not allow_legacy:
            return len(entries), [f"chain declares legacy schema {sch}; the SV-2 cutover verifies "
                                  f"v{_ledger.CURRENT_MAJOR} — set LEDGER_ALLOW_LEGACY to audit a v{sch} chain"], \
                f"chain-v{sch}-refused"
        _ok, problems = _ledger.verify_chain(entries, sch, expect_run_id, expect_plan_sha)
        return len(entries), problems, f"chain-v{sch}"
    return (*verify_structural(ledger), "structural")


def _load(target):
    """Load TARGET_LEDGER as JSON (object/list) or, failing that, JSONL (the v2 append-only form)."""
    raw = open(target).read()
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return [json.loads(ln) for ln in raw.splitlines() if ln.strip()]


def main() -> int:
    target = os.environ["TARGET_LEDGER"]
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "ledgercheck.json")
    os.makedirs(store, exist_ok=True)
    expect_run_id = os.environ.get("EXPECT_RUN_ID") or None       # out-of-band origin -> certifies non-transplant
    expect_plan_sha = os.environ.get("EXPECT_PLAN_SHA") or None
    allow_legacy = os.environ.get("LEDGER_ALLOW_LEGACY", "").lower() in ("1", "true", "yes")
    try:
        ledger = _load(target)
        records, bad, mode = verify(ledger, expect_run_id=expect_run_id,
                                    expect_plan_sha=expect_plan_sha, allow_legacy=allow_legacy)
    except Exception as e:                                        # a hostile ledger must read 'broken', never crash
        json.dump({"target": target, "chain": "broken", "records": 0, "bad_records": [f"unreadable: {e}"]},
                  open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_ledgerverify", "status": "broken", "reason": "unreadable", "report": out}))
        return 1
    chain = "ok" if not bad else "broken"
    report = {"target": target, "mode": mode,
              "script": ledger.get("script") if isinstance(ledger, dict) else None,
              "records": records, "bad_records": bad, "chain": chain}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_ledgerverify", "status": chain, "mode": mode, "records": records,
                      "bad_records": len(bad), "report": out}))
    return 0 if chain == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
