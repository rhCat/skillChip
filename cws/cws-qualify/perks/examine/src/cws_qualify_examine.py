#!/usr/bin/env python3
"""cws_qualify_examine — the examiner-rung gate: an EARNED Q-record + LINEAGE INDEPENDENCE (Q3 / H6).

An examiner writes instrument-backed verdicts on OTHERS' work — so two things must hold before a lot
may examine: (1) EARNED standing — a passing Q-record in the Q-ledger at composer rung or above whose
scope covers the requested scope; (2) LINEAGE INDEPENDENCE — the examiner lot and the producer lot
whose work it would examine share no ancestry line (neither is the other, an ancestor, or a
descendant, per the LINEAGE map `{lot: [parent lots]}`). H6, the entrenchment clause: the second
lineage is constitutional — self-examination may never be optimized away. Fail-closed: no Q-record,
uncovered scope, unknown lineage, or a shared line all REFUSE.

Reads PERFORMER_LOT, PRODUCER_LOT, Q_LEDGER, LINEAGE (+ optional SCOPE) + RECORD_STORE from env;
writes RECORD_STORE/examine.json + one JSON line. Exit 0 iff the lot may examine, else 1.
"""
from __future__ import annotations
import json
import os
import sys

RUNG_ORDER = {"executor": 0, "composer": 1, "grower": 2, "examiner": 3}


def ancestry(lot, lineage, _seen=None):
    """The lot's transitive parent set per the LINEAGE map (cycle-safe)."""
    seen = _seen if _seen is not None else set()
    for p in lineage.get(lot, []):
        if p not in seen:
            seen.add(p)
            ancestry(p, lineage, seen)
    return seen


def scope_covers(earned, wanted):
    """Every wanted scope item appears in the earned scope (comma lists; empty wanted = covered)."""
    e = {s.strip() for s in (earned or "").split(",") if s.strip()}
    w = {s.strip() for s in (wanted or "").split(",") if s.strip()}
    return w <= e


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "examine.json")
    os.makedirs(store, exist_ok=True)
    performer = (os.environ.get("PERFORMER_LOT") or "").strip()
    producer = (os.environ.get("PRODUCER_LOT") or "").strip()
    q_path = os.environ.get("Q_LEDGER", "")
    lineage_path = os.environ.get("LINEAGE", "")
    scope = (os.environ.get("SCOPE") or "").strip()

    def verdict(ok, reason, extra=None):
        rep = {"tool": "cws_qualify_examine", "verdict": "pass" if ok else "refused",
               "performer_lot": performer, "producer_lot": producer, "scope": scope, "reason": reason}
        rep.update(extra or {})
        json.dump(rep, open(out, "w"), indent=2)
        print(json.dumps({k: rep[k] for k in ("tool", "verdict", "reason")} | {"report": out}))
        return 0 if ok else 1

    if not performer or not producer:
        return verdict(False, "PERFORMER_LOT and PRODUCER_LOT are both required")
    if performer == producer:
        return verdict(False, "a lot may not examine its own work (H6: the second lineage is constitutional)")
    if not q_path or not os.path.isfile(q_path):
        return verdict(False, f"Q_LEDGER not a file: {q_path} — standing is earned, never asserted")

    entries = json.load(open(q_path)).get("entries", [])
    earned = [e for e in entries
              if e.get("lot") == performer and e.get("verdict") == "pass"
              and RUNG_ORDER.get(e.get("rung"), -1) >= RUNG_ORDER["composer"]
              and scope_covers(e.get("scope"), scope)]
    if not earned:
        return verdict(False, "no passing Q-record at composer rung or above covering the requested scope",
                       {"q_records_for_lot": sum(1 for e in entries if e.get("lot") == performer)})

    if not lineage_path or not os.path.isfile(lineage_path):
        return verdict(False, f"LINEAGE not a file: {lineage_path} — unknown lineage cannot prove independence (fail-closed)")
    lineage = json.load(open(lineage_path))
    if performer not in lineage or producer not in lineage:
        return verdict(False, "a lot absent from the LINEAGE map cannot prove independence (fail-closed)")
    a_perf, a_prod = ancestry(performer, lineage), ancestry(producer, lineage)
    if performer in a_prod or producer in a_perf:
        return verdict(False, "shared lineage line — the examiner is an ancestor/descendant of the producer",
                       {"performer_ancestry": sorted(a_perf), "producer_ancestry": sorted(a_prod)})

    return verdict(True, "earned Q-record + lineage independence hold",
                   {"qualifying_record": earned[-1],
                    "performer_ancestry": sorted(a_perf), "producer_ancestry": sorted(a_prod)})


if __name__ == "__main__":
    sys.exit(main())
