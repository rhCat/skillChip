#!/usr/bin/env python3
"""cws_pm — the composite/operator skill: drive a PLAYBOOK of sub-skills, tracking + steering against the plan.

A composite skill doesn't run its own tools — it FIRES a sequence of other skills (the "caller skills")
through the governed channel, the way a top-layer project manager follows a plan and adjusts. The playbook
is data: an ordered list of steps, each `{task_id, skill, perk, vars, redeem}`. For each step this core:

  1. SKIPS it if the task is already redeemed (idempotent — reads the done-ledger v1 + v2),
  2. else fires the sub-skill's validator through govd (run_governed); a non-allow decision (e.g.
     registry_drift / blocked deps) or a non-ok step is recorded as blocked/failed,
  3. and, when the step asks, REDEEMS the task via cws-observe/redeem on that governed run's own ledger.

It steers (stop_on_fail) and reports per-step + a roll-up — the tracking layer the operator reads to adjust
the playbook. DRY_RUN validates the playbook (every skill/perk exists in the chip) WITHOUT firing.

env: PLAYBOOK, GOVD_URL (default http://127.0.0.1:5773), SWARM_DIR, DONE_LEDGER (default swarm/done-ledger.json),
GOVD_ROOT (default ~/cyberware_govd), RECORD_STORE, optional DRY_RUN, STOP_ON_FAIL. Writes RECORD_STORE/pm.json.
"""
from __future__ import annotations
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra import registry  # noqa: E402
from infra.govern import govd_client  # noqa: E402


def _redeemed(swarm):
    """task_ids with a pass entry in either done-ledger chain (v1 frozen + v2 canonical)."""
    done = set()
    for fn in ("done-ledger.json", "done-ledger-v2.json"):
        p = os.path.join(swarm, fn)
        if os.path.isfile(p):
            for e in json.load(open(p)).get("entries", []):
                if e.get("verdict") == "pass":
                    done.add(e.get("task_id"))
    return done


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "pm.json")
    os.makedirs(store, exist_ok=True)
    playbook = json.load(open(os.environ["PLAYBOOK"]))
    steps = playbook if isinstance(playbook, list) else playbook.get("steps", [])
    govd = os.environ.get("GOVD_URL", "http://127.0.0.1:5773")
    swarm = os.environ.get("SWARM_DIR", "")
    done_ledger = os.environ.get("DONE_LEDGER") or (os.path.join(swarm, "done-ledger.json") if swarm else "")
    govd_root = os.path.expanduser(os.environ.get("GOVD_ROOT", "~/cyberware_govd"))
    dry = os.environ.get("DRY_RUN", "").lower() in ("1", "true", "yes")
    stop_on_fail = os.environ.get("STOP_ON_FAIL", "").lower() in ("1", "true", "yes")

    redeemed = _redeemed(swarm) if swarm else set()
    results, counts = [], {"redeemed": 0, "skipped": 0, "failed": 0, "blocked": 0, "dry": 0}

    for st in steps:
        tid, skill, perk = st.get("task_id"), st.get("skill"), st.get("perk")
        rec = {"task_id": tid, "skill": skill, "perk": perk}
        if not os.path.isdir(os.path.join(registry.SKILLCHIP, skill or "")):
            rec["status"] = "error"; rec["detail"] = f"unknown skill: {skill}"; counts["failed"] += 1
            results.append(rec)
            if stop_on_fail:
                break
            continue
        if tid and tid in redeemed:
            rec["status"] = "skipped"; rec["detail"] = "already redeemed"; counts["skipped"] += 1
            results.append(rec); continue
        if dry:
            rec["status"] = "dry"; rec["detail"] = "would fire"; counts["dry"] += 1
            results.append(rec); continue

        rs = os.path.join(store, f"step-{tid or skill}")
        os.makedirs(rs, exist_ok=True)
        r = govd_client.run_governed(govd, {"skill": skill, "perk": perk, "record_store": rs, "vars": st.get("vars", {})})
        if r.get("decision") != "allow" or r.get("error"):
            rec["status"] = "blocked"; rec["detail"] = r.get("error") or f"decision={r.get('decision')}"
            counts["blocked"] += 1; results.append(rec)
            if stop_on_fail:
                break
            continue
        if any(s.get("exit") not in (0, None) for s in r.get("results", [])):
            rec["status"] = "failed"; rec["detail"] = f"steps={r.get('results')}"; counts["failed"] += 1
            results.append(rec)
            if stop_on_fail:
                break
            continue
        rec["status"] = "ran"; rec["run_id"] = r.get("run_id")
        if st.get("redeem") and tid and swarm:                # redeem on THIS governed run's own ledger
            evidence = os.path.join(govd_root, r["run_id"], "ledger.json")
            govd_client.run_governed(govd, {"skill": "cws-observe", "perk": "redeem",
                 "record_store": os.path.join(rs, "redeem"),
                 "vars": {"SWARM_DIR": swarm, "TASK_ID": tid, "RUN_LEDGER": evidence, "DONE_LEDGER": done_ledger}})
            redj = json.load(open(os.path.join(rs, "redeem", "redeem.json"))) if os.path.isfile(os.path.join(rs, "redeem", "redeem.json")) else {}
            if redj.get("verdict") == "pass":
                rec["status"] = "redeemed"; counts["redeemed"] += 1
            else:
                rec["redeem"] = redj.get("verdict"); rec["detail"] = redj.get("reason", "")
        results.append(rec)

    status = "ok" if counts["failed"] == 0 and counts["blocked"] == 0 else "fail"
    report = {"status": status, "dry_run": dry, "total": len(steps), "counts": counts, "steps": results}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_pm", "status": status, "counts": counts, "report": out}))
    return 0 if status == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
