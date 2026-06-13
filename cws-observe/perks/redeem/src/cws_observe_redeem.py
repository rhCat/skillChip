#!/usr/bin/env python3
"""cws_observe_redeem — record a task's REDEMPTION to the done-ledger, gated on real evidence.

This is the only writer of the done-ledger, and it never takes anyone's word: a task is redeemed only
when a *governed validator run-ledger* shows the validator ran and PASSED (every recorded step ok, no
refusal event). It then appends a prev-hash-chained entry — `{seq, ts, task_id, validator, verdict,
evidence_sha, prev}` — so the progress record is itself tamper-evident (a flipped verdict breaks the
chain, which cws-observe/status reports).

Reads from env: SWARM_DIR, TASK_ID, RUN_LEDGER (the governed run-ledger evidencing the pass), DONE_LEDGER
(created if absent), RECORD_STORE. Exit 0 on a recorded (or already-present) redemption; nonzero if the
evidence does not show a clean pass, or the task/validator does not match.
"""
from __future__ import annotations
import hashlib
import json
import os
import sys
import time

REFUSAL_EVENTS = {"tamper_refused", "oversight_refused"}


def _canon(obj):
    return json.dumps(obj, sort_keys=True).encode()


def run_ledger_passed(rl):
    """A governed run-ledger evidences a clean pass. Two accepted shapes:
    - govd provenance ledger (the audit plane): `{decision:"allow", events:[{type:"step_result",status:"ok"},...]}`
      — every step_result ok, no refusal, decision allowed. This is the dashboard-visible, value-free record.
    - executor run-ledger (local channel): `{runs:[{step,status:"ok",...}]}` — every step record ok, no refusal."""
    if isinstance(rl, dict) and "events" in rl:                 # govd provenance ledger
        if rl.get("decision") != "allow":
            return False, f"govd decision is {rl.get('decision')!r}, not allow"
        evs = rl["events"]
        if any(e.get("type") in REFUSAL_EVENTS for e in evs):
            return False, "a refusal event is recorded (tamper/oversight)"
        results = [e for e in evs if e.get("type") == "step_result"]
        if not results:
            return False, "no step_result events — nothing ran"
        if not all(e.get("status") == "ok" for e in results):
            return False, f"step(s) {[e.get('step') for e in results if e.get('status') != 'ok']} did not finish ok"
        return True, "ok"
    runs = (rl or {}).get("runs")
    if not isinstance(runs, list):
        return False, "run-ledger has neither govd events[] nor executor runs[]"
    steps = [r for r in runs if "step" in r and "event" not in r]
    if any(r.get("event") in REFUSAL_EVENTS for r in runs):
        return False, "a refusal event is recorded (tamper/oversight)"
    if not steps:
        return False, "no step records — nothing ran"
    if not all(r.get("status") == "ok" for r in steps):
        bad = [r.get("step") for r in steps if r.get("status") != "ok"]
        return False, f"step(s) {bad} did not finish ok"
    return True, "ok"


def main() -> int:
    swarm = os.environ["SWARM_DIR"]
    task_id = os.environ["TASK_ID"]
    run_ledger_path = os.environ["RUN_LEDGER"]
    done_ledger_path = os.environ.get("DONE_LEDGER", os.path.join(swarm, "done-ledger.json"))
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "redeem.json")
    os.makedirs(store, exist_ok=True)

    def refuse(reason):
        json.dump({"task_id": task_id, "verdict": "refused", "reason": reason}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_observe_redeem", "task_id": task_id, "verdict": "refused",
                          "reason": reason, "report": out}))
        return 1

    tpath = os.path.join(swarm, f"{task_id}.json")
    if not os.path.isfile(tpath):
        return refuse(f"no such task in swarm: {task_id}")
    validator = json.load(open(tpath)).get("validated_by")

    if not os.path.isfile(run_ledger_path):
        return refuse(f"run-ledger not found: {run_ledger_path}")
    evidence = json.load(open(run_ledger_path))
    passed, why = run_ledger_passed(evidence)
    if not passed:
        return refuse(f"evidence does not show a clean pass: {why}")

    # bind the evidence to the right validator: a govd ledger carries `skill` directly; an executor
    # run-ledger carries identity in a sibling task-ledger.json.
    ran_skill = evidence.get("skill") if "events" in evidence else None
    if ran_skill is None:
        sib = os.path.join(os.path.dirname(os.path.abspath(run_ledger_path)), "task-ledger.json")
        if os.path.isfile(sib):
            ran_skill = json.load(open(sib)).get("skill")
    if validator and ran_skill and ran_skill != validator:
        return refuse(f"evidence is from '{ran_skill}', but {task_id} is validated_by '{validator}'")

    led = json.load(open(done_ledger_path)) if os.path.isfile(done_ledger_path) else {"chain": "done-ledger", "entries": []}
    entries = led.setdefault("entries", [])
    if any(e.get("task_id") == task_id and e.get("verdict") == "pass" for e in entries):
        json.dump({"task_id": task_id, "verdict": "pass", "note": "already redeemed"}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_observe_redeem", "task_id": task_id, "verdict": "pass",
                          "note": "already redeemed", "report": out}))
        return 0

    prev = "0" * 64
    if entries:
        last = entries[-1]
        prev = hashlib.sha256(_canon({k: last[k] for k in last if k != "prev"})).hexdigest()
    entry = {"seq": len(entries) + 1, "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
             "task_id": task_id, "validator": validator, "verdict": "pass",
             "evidence_sha": hashlib.sha256(open(run_ledger_path, "rb").read()).hexdigest(), "prev": prev}
    entries.append(entry)
    os.makedirs(os.path.dirname(os.path.abspath(done_ledger_path)), exist_ok=True)
    json.dump(led, open(done_ledger_path, "w"), indent=2)

    json.dump({"task_id": task_id, "validator": validator, "verdict": "pass", "seq": entry["seq"],
               "evidence_sha": entry["evidence_sha"], "done_ledger": done_ledger_path}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_observe_redeem", "task_id": task_id, "validator": validator,
                      "verdict": "pass", "seq": entry["seq"], "report": out}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
