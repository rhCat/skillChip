#!/usr/bin/env python3
"""cws_lotquery — query a node's governed-run ledger store by LOT and report per-lot yield.

The store index (idx_origin / idx_decision / idx_record) is the queryable face of the per-node
tamper-evident chains: every governed run leaves its origin (run_id -> plan_sha), its governance
verdict, and its per-step results there, value-free. This perk turns that raw index into a LOT
report: runs grouped by a key (default `plan_sha` — the blessed plan IS the lot identity; the
`generation_context` key can slot in when the store records one), each lot rolled up as
`{lot, runs, decisions{allow,reject,...}, steps{ok,fail}, runs_all_ok, first_ts, last_ts, skills,
perks, principals}` — the evidence a Q-ladder examiner or an operator reads to see what a lot has
actually done. It only READS: sqlite is opened read-only (mode=ro URI), a Postgres DSN (a shared
warehouse, if an operator ever wires one) is accepted through the same SQL — the perk is
backend-agnostic on purpose so the store migration stays a deployment decision, not a perk change.

Reads from env: LEDGER_DB (required — path to the store's index.sqlite, or a postgresql:// DSN),
GROUP_BY (plan_sha | skill | perk | principal; default plan_sha), LOT (optional filter — exact or
prefix match on the group key), SINCE (optional ISO-8601 lower bound on ts), LIMIT (default 50),
RECORD_STORE. Writes RECORD_STORE/lotquery.json + one JSON line. Exit 0 on a completed query (zero
lots is a valid answer); nonzero fail-closed on a missing/unreadable store or a bad GROUP_BY.
"""
from __future__ import annotations
import json
import os
import sys

GROUP_KEYS = ("plan_sha", "skill", "perk", "principal")


def open_store(target):
    """Open the ledger store read-only. A path opens sqlite (mode=ro URI — never touches the live
    WAL); a DSN-looking target lazily imports psycopg. Returns (connection, kind)."""
    if target.startswith(("postgresql://", "postgres://")) or target.startswith("dbname="):
        import psycopg                                      # lazy: only for a wired warehouse
        return psycopg.connect(target, autocommit=True), "postgres"
    if not os.path.isfile(target):
        raise FileNotFoundError(f"ledger store not a file: {target}")
    import sqlite3
    cx = sqlite3.connect(f"file:{os.path.abspath(target)}?mode=ro", uri=True)
    return cx, "sqlite"


def load_rows(cx):
    """Pull the three index tables with plain SELECTs (no dialect features — the same SQL runs on
    sqlite and Postgres); all shaping happens in Python."""
    origins = {r[0]: r[1] for r in cx.execute("SELECT run_id, plan_sha FROM idx_origin")}
    decisions = [{"run_id": r[0], "ts": r[1], "fields": json.loads(r[2] or "{}")}
                 for r in cx.execute("SELECT run_id, ts, fields FROM idx_decision")]
    events = [{"run_id": r[0], "ts": r[1], "plan_sha": r[2], "fields": json.loads(r[3] or "{}")}
              for r in cx.execute("SELECT run_id, ts, plan_sha, fields FROM idx_record")]
    return origins, decisions, events


def lot_key(run_id, dec_fields, origins, group_by):
    """The group key for one run: plan_sha comes from the origin binding; skill/perk/principal come
    from the decision record. A run missing the key groups under '(unknown)' — visible, not dropped."""
    if group_by == "plan_sha":
        return origins.get(run_id) or "(unknown)"
    return (dec_fields or {}).get(group_by) or "(unknown)"


def rollup(origins, decisions, events, group_by, lot_filter, since):
    """Group runs into lots and measure each: verdict counts, step pass/fail, whether every step of
    every run passed, the activity window, and the distinct skills/perks/principals seen."""
    # decision fields per run (the run's who/what); a run may lack one (index written mid-run)
    dec_by_run = {}
    for d in decisions:
        dec_by_run.setdefault(d["run_id"], d["fields"])

    lots = {}

    def lot_for(run_id):
        key = lot_key(run_id, dec_by_run.get(run_id), origins, group_by)
        if lot_filter and not key.startswith(lot_filter):
            return None
        return lots.setdefault(key, {
            "lot": key, "runs": set(), "decisions": {}, "destructive": 0,
            "steps": {"ok": 0, "fail": 0}, "bad_runs": set(),
            "skills": set(), "perks": set(), "principals": set(),
            "first_ts": None, "last_ts": None})

    def touch(lot, ts):
        if ts:
            lot["first_ts"] = ts if lot["first_ts"] is None else min(lot["first_ts"], ts)
            lot["last_ts"] = ts if lot["last_ts"] is None else max(lot["last_ts"], ts)

    for d in decisions:
        if since and (d["ts"] or "") < since:
            continue
        lot = lot_for(d["run_id"])
        if lot is None:
            continue
        f = d["fields"]
        lot["runs"].add(d["run_id"])
        verdict = f.get("decision") or "(none)"
        lot["decisions"][verdict] = lot["decisions"].get(verdict, 0) + 1
        if verdict != "allow":
            lot["bad_runs"].add(d["run_id"])
        if f.get("destructive"):
            lot["destructive"] += 1
        for axis in ("skill", "perk", "principal"):
            if f.get(axis):
                lot[axis + "s"].add(f[axis])
        touch(lot, d["ts"])

    for e in events:
        if since and (e["ts"] or "") < since:
            continue
        f = e["fields"]
        if f.get("type") != "step_result":
            continue
        lot = lot_for(e["run_id"])
        if lot is None:
            continue
        lot["runs"].add(e["run_id"])
        ok = f.get("status") == "ok"
        lot["steps"]["ok" if ok else "fail"] += 1
        if not ok:
            lot["bad_runs"].add(e["run_id"])
        touch(lot, e["ts"])

    rows = []
    for lot in lots.values():
        rows.append({"lot": lot["lot"], "runs": len(lot["runs"]),
                     "decisions": lot["decisions"], "destructive": lot["destructive"],
                     "steps": lot["steps"],
                     "runs_all_ok": len(lot["runs"] - lot["bad_runs"]),
                     "skills": sorted(lot["skills"]), "perks": sorted(lot["perks"]),
                     "principals": sorted(lot["principals"]),
                     "first_ts": lot["first_ts"], "last_ts": lot["last_ts"]})
    rows.sort(key=lambda r: (r["last_ts"] or "", r["lot"]), reverse=True)
    return rows


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "lotquery.json")
    os.makedirs(store, exist_ok=True)
    target = (os.environ.get("LEDGER_DB") or "").strip()
    group_by = (os.environ.get("GROUP_BY") or "plan_sha").strip()
    lot_filter = (os.environ.get("LOT") or "").strip()
    since = (os.environ.get("SINCE") or "").strip()
    try:
        limit = int(os.environ.get("LIMIT") or "50")
    except ValueError:
        limit = 50

    def refuse(reason):
        json.dump({"tool": "cws_lotquery", "verdict": "refused", "reason": reason}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_lotquery", "verdict": "refused", "reason": reason, "report": out}))
        return 1

    if not target:
        return refuse("LEDGER_DB is required — the store's index.sqlite path, or a postgresql:// DSN")
    if group_by not in GROUP_KEYS:
        return refuse(f"GROUP_BY {group_by!r} not one of {list(GROUP_KEYS)} (fail-closed)")

    try:
        cx, kind = open_store(target)
    except Exception as e:
        return refuse(f"cannot open ledger store read-only: {e}")
    try:
        origins, decisions, events = load_rows(cx)
    except Exception as e:
        cx.close()
        return refuse(f"store query failed (not a ledger index?): {e}")
    cx.close()

    rows = rollup(origins, decisions, events, group_by, lot_filter, since)
    truncated = len(rows) > limit
    report = {"tool": "cws_lotquery", "verdict": "ok", "backend": kind, "group_by": group_by,
              "filter": {"lot": lot_filter or None, "since": since or None},
              "totals": {"runs": len({r for r in origins} | {d["run_id"] for d in decisions}),
                         "lots": len(rows)},
              "truncated": truncated, "limit": limit, "lots": rows[:limit]}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_lotquery", "verdict": "ok", "backend": kind, "group_by": group_by,
                      "lots": len(rows), "truncated": truncated, "report": out}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
