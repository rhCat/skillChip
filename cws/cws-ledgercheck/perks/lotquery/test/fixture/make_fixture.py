#!/usr/bin/env python3
"""Builds index.sqlite — a miniature of the store backend's real index schema (idx_origin /
idx_decision / idx_record) with two lots: plan AAA (2 runs, all allow, all steps ok) and plan BBB
(2 runs: one allow with a failed step, one reject). Deterministic; re-run to regenerate."""
import json
import os
import sqlite3

here = os.path.dirname(os.path.abspath(__file__))
db = os.path.join(here, "index.sqlite")
if os.path.exists(db):
    os.remove(db)
cx = sqlite3.connect(db)
cx.executescript("""
CREATE TABLE idx_origin  (run_id TEXT, plan_sha TEXT);
CREATE TABLE idx_decision(rid INTEGER PRIMARY KEY AUTOINCREMENT, run_id TEXT, ts TEXT,
                          link_digest TEXT, fields TEXT);
CREATE TABLE idx_record  (run_id TEXT, seq INTEGER, prev TEXT, link_digest TEXT, kind TEXT,
                          ts TEXT, plan_sha TEXT, fields TEXT);
""")
AAA, BBB = "a" * 64, "b" * 64


def run(run_id, plan, ts, decision, skill, perk, principal, steps):
    cx.execute("INSERT INTO idx_origin VALUES (?,?)", (run_id, plan))
    cx.execute("INSERT INTO idx_decision (run_id, ts, link_digest, fields) VALUES (?,?,?,?)",
               (run_id, ts, "d" * 64, json.dumps({"decision": decision, "skill": skill,
                "perk": perk, "principal": principal, "destructive": False, "plan_sha": plan})))
    for i, status in enumerate(steps, 1):
        cx.execute("INSERT INTO idx_record VALUES (?,?,?,?,?,?,?,?)",
                   (run_id, i, "p" * 64, "l" * 64, "event", ts, plan,
                    json.dumps({"type": "step_result", "step": str(i), "status": status,
                                "exit": 0 if status == "ok" else 1})))


run("run-a1", AAA, "2026-07-01T10:00:00Z", "allow", "cws:demo", "one", "mac-coop", ["ok", "ok"])
run("run-a2", AAA, "2026-07-02T10:00:00Z", "allow", "cws:demo", "one", "mac-coop", ["ok"])
run("run-b1", BBB, "2026-07-03T10:00:00Z", "allow", "cws:demo", "two", "agent-1", ["ok", "fail"])
run("run-b2", BBB, "2026-07-04T10:00:00Z", "reject", "cws:demo", "two", "agent-1", [])
cx.commit()
cx.close()
print(f"wrote {db}")
