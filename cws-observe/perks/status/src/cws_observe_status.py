#!/usr/bin/env python3
"""cws_observe_status — oversee a task-DAG's progress against the plan, by REDEMPTION not assertion.

The plan's governing rule: a task is *redeemed*, not asserted — its `status` field is an untrusted hint;
the truth is a verified, governed validator run recorded in the done-ledger. This reads the swarm DAG
(every P*-T*.json + _swarm_manifest.json) and the done-ledger (which cws-observe/redeem appends to,
prev-hash chained), then classifies each task:

  redeemed            a pass entry for it exists in the (chain-verified) done-ledger
  ready               not redeemed, its validator skill EXISTS in the chip, and every dep is redeemed
  blocked: deps       its validator exists but a dependency is not yet redeemed
  blocked: validator  its `validated_by` skill is not built in the chip yet (infra-blocked)

Validator availability is read from the live chip (registry.SKILLCHIP), so the picture updates itself as
validators get built. It also rolls the manifest's milestones (M0..M6) up to closure.

Reads SWARM_DIR (+ optional DONE_LEDGER) from env; writes RECORD_STORE/observe.json + one JSON line.
Exit 0 normally (incomplete progress is the normal state); nonzero only if the done-ledger is corrupt.
"""
from __future__ import annotations
import glob
import hashlib
import json
import os
import sys

# locate the cyberware repo root so we can read the live chip (which validators exist)
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra import registry  # noqa: E402


def _canon(obj):
    return json.dumps(obj, sort_keys=True).encode()


def read_done_ledger(path):
    """Return (redeemed_task_ids:set, chain_status:str). The done-ledger is a prev-hash chain; a broken
    link means the progress record itself was tampered with."""
    if not path or not os.path.isfile(path):
        return set(), "absent"
    led = json.load(open(path))
    entries = led.get("entries", [])
    redeemed, prev = set(), "0" * 64
    chain = "ok"
    for e in entries:
        link = {k: e[k] for k in e if k != "prev"}
        if e.get("prev") != prev:
            chain = "broken"
        prev = hashlib.sha256(_canon(link)).hexdigest()
        if e.get("verdict") == "pass":
            redeemed.add(e.get("task_id"))
    return redeemed, chain


def load_dag(swarm_dir):
    tasks = {}
    for f in glob.glob(os.path.join(swarm_dir, "P*-T*.json")):
        d = json.load(open(f))
        tasks[d["task_id"]] = d
    mpath = os.path.join(swarm_dir, "_swarm_manifest.json")
    manifest = json.load(open(mpath)) if os.path.isfile(mpath) else {}
    return tasks, manifest


def main() -> int:
    swarm = os.environ["SWARM_DIR"]
    done_ledger = os.environ.get("DONE_LEDGER", os.path.join(swarm, "done-ledger.json"))
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "observe.json")
    os.makedirs(store, exist_ok=True)

    tasks, manifest = load_dag(swarm)
    redeemed, chain = read_done_ledger(done_ledger)
    redeemed &= set(tasks)                                     # only count redemptions for tasks in this DAG

    def validator_built(t):
        v = t.get("validated_by")
        return bool(v) and os.path.isdir(os.path.join(registry.SKILLCHIP, v))

    state = {}
    for tid, t in tasks.items():
        if tid in redeemed:
            state[tid] = "redeemed"
        elif not validator_built(t):
            state[tid] = "blocked:validator"
        elif all(d in redeemed for d in t.get("depends_on", [])):
            state[tid] = "ready"
        else:
            state[tid] = "blocked:deps"

    counts = {s: sum(1 for v in state.values() if v == s)
              for s in ("redeemed", "ready", "blocked:deps", "blocked:validator")}
    validators = sorted({t.get("validated_by") for t in tasks.values() if t.get("validated_by")})
    available = sorted(v for v in validators if os.path.isdir(os.path.join(registry.SKILLCHIP, v)))
    missing = sorted(set(validators) - set(available))

    # a milestone's closure is the transitive dependency cone of its gate task(s): the milestone is
    # closed when the gate AND everything it depends on are all redeemed.
    def cone_of(gates):
        seen, stack = set(), list(gates)
        while stack:
            n = stack.pop()
            if n in seen:
                continue
            seen.add(n)
            stack += tasks.get(n, {}).get("depends_on", [])
        return seen

    milestones = []
    for m in manifest.get("milestones", []):
        gate = m.get("gate_tasks", m.get("gate", m.get("gate_task")))
        gates = gate if isinstance(gate, list) else ([gate] if gate else [])
        cone = cone_of(gates)
        milestones.append({
            "id": m.get("id"), "rung": m.get("rung") or m.get("ladder"), "gate": gates,
            "closure": len(cone), "redeemed": len(cone & redeemed),
            "gate_redeemed": all(g in redeemed for g in gates) if gates else None,
            "closed": bool(cone) and cone <= redeemed,
            "promise": m.get("promise_outward") or m.get("promise"),
        })

    report = {
        "swarm_dir": swarm, "total": len(tasks), "done_ledger_chain": chain,
        "counts": counts,
        "next_pullable": sorted(tid for tid, s in state.items() if s == "ready"),
        "validators_available": available, "validators_missing": missing,
        "milestones": milestones,
        "by_task": {tid: state[tid] for tid in sorted(tasks)},
    }
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_observe_status", "total": len(tasks), "redeemed": counts["redeemed"],
                      "ready": counts["ready"], "blocked_validator": counts["blocked:validator"],
                      "done_ledger_chain": chain, "report": out}))
    return 1 if chain == "broken" else 0


if __name__ == "__main__":
    sys.exit(main())
