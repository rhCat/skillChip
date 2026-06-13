#!/usr/bin/env python3
"""cws_ledgerverify — verify a run-ledger is a sound provenance chain (structural + ordering).

The SV-2 precursor: evidence stops being a log someone trusts and becomes an independently re-verifiable
record. This walks the executor's `run-ledger.json` (the format written by infra/govern/executor.py) and
asserts its invariants:
  * structure — a `script` string and a `runs` list; every run carries a `ts`;
  * step records — an `ok` step carries `exit` + `stdout_sha` (the provenance hash);
  * events — refusals/waivers (`tamper_refused`, `oversight_refused`, `oversight_waived`) are recognised
    as evidence, not corruption (meta-rule M4: a recorded refusal is a pass);
  * ordering — the `ok` step records form a contiguous prefix 1..N. A gap means a step ran out of band
    (the executor's upstream gate would never leave one), so a hole in the chain is named.

Reads TARGET_LEDGER + RECORD_STORE from env; writes RECORD_STORE/ledgercheck.json + one structured JSON
line. Exit 0 iff the chain is sound (no bad records, no gap), nonzero otherwise.

NOTE (scope): today's run-ledger is a structural chain, not yet the cryptographic `prev`/HMAC chain of
Ledger-v2 (plan P1). This perk verifies what exists now; `torture` / `crashloop` arrive with Ledger-v2.
"""
from __future__ import annotations
import json
import os
import sys

EVENT_KINDS = {"tamper_refused", "oversight_refused", "oversight_waived"}


def verify(ledger):
    """Return (records, bad): bad is a list of problem strings — empty bad means the chain is sound."""
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


def main() -> int:
    target = os.environ["TARGET_LEDGER"]
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "ledgercheck.json")
    os.makedirs(store, exist_ok=True)
    try:
        ledger = json.load(open(target))
    except Exception as e:
        json.dump({"target": target, "chain": "broken", "records": 0, "bad_records": [f"unreadable: {e}"]},
                  open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_ledgerverify", "status": "broken", "reason": "unreadable", "report": out}))
        return 1
    records, bad = verify(ledger)
    chain = "ok" if not bad else "broken"
    report = {"target": target, "script": ledger.get("script") if isinstance(ledger, dict) else None,
              "records": records, "bad_records": bad, "chain": chain}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_ledgerverify", "status": chain, "records": records,
                      "bad_records": len(bad), "report": out}))
    return 0 if chain == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
