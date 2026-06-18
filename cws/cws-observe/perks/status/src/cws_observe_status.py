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
from infra.cwp import ledger  # noqa: E402


def _verify_chain(entries, schema):
    """Verify a prev-hash chain under `schema`. Returns (redeemed_task_ids:set, ok:bool)."""
    redeemed, prev, ok = set(), "0" * 64, True
    for e in entries:
        if e.get("prev") != prev:
            ok = False
        prev = ledger.link_digest(ledger.link_of(e), schema)
        if e.get("verdict") == "pass":
            redeemed.add(e.get("task_id"))
    return redeemed, ok


def read_done_ledger(path):
    """Return (redeemed_task_ids:set, chain_status:str). The done-ledger is a prev-hash chain; a broken
    link means the progress record itself was tampered with. Reads the v1 chain at `path` (schema major
    recorded in the chain; absent => major 1, the frozen original) AND a v2 chain at the sibling
    done-ledger-v2.json if present (inflight.md decision 4: a schema migration is a NEW chain carrying a
    cross-reference to the old one — never a rewrite — and verifiers support majors N and N-1). The v2
    genesis MUST cross-reference v1's exact head, so any alteration of frozen v1 breaks the chain."""
    if not path or not os.path.isfile(path):
        return set(), "absent"
    v1 = json.load(open(path))
    v1_entries = v1.get("entries", [])
    v1_schema = v1.get("schema", 1)
    redeemed, ok = _verify_chain(v1_entries, v1_schema)
    chain = "ok" if ok else "broken"

    v2path = os.path.join(os.path.dirname(os.path.abspath(path)), "done-ledger-v2.json")
    if os.path.isfile(v2path):
        v2 = json.load(open(v2path))
        v2_entries = v2.get("entries", [])
        v2_schema = v2.get("schema", ledger.CURRENT_MAJOR)
        g = v2_entries[0] if v2_entries else None
        if not g or g.get("type") != "genesis":
            chain = "broken"                                       # a v2 chain must open with a genesis record
        elif g.get("supersedes_head") != ledger.head_of(v1_entries, v1_schema):
            chain = "broken"                                       # genesis cross-ref doesn't match v1's head
        r2, ok2 = _verify_chain(v2_entries, v2_schema)
        if not ok2:
            chain = "broken"
        redeemed |= r2
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
        return bool(v) and os.path.isfile(os.path.join(registry.skill_dir(v), "perks.json"))

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
    available = sorted(v for v in validators if os.path.isfile(os.path.join(registry.skill_dir(v), "perks.json")))
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
