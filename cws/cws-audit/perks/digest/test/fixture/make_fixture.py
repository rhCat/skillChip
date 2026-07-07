#!/usr/bin/env python3
"""Builds the audit fixture: an index.sqlite with a mixed history (clean runs, a failed step, a
reject, a destructive approval, a tamper refusal) + a small VALID backup-ledger.json (built with
infra.cwp.ledger so its genesis is origin-bound — run with PYTHONPATH=<cyberware repo>).
Deterministic; re-run to regenerate."""
import hashlib
import json
import os
import sqlite3
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if _root:
    sys.path.insert(0, _root)
from infra.cwp import ledger  # noqa: E402

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


def dec(run_id, ts, **f):
    cx.execute("INSERT INTO idx_decision (run_id, ts, link_digest, fields) VALUES (?,?,?,?)",
               (run_id, ts, "d" * 64, json.dumps(f)))


def ev(run_id, seq, ts, plan, **f):
    cx.execute("INSERT INTO idx_record VALUES (?,?,?,?,?,?,?,?)",
               (run_id, seq, "p" * 64, "l" * 64, "event", ts, plan, json.dumps(f)))


P1, P2 = "a" * 64, "b" * 64
cx.execute("INSERT INTO idx_origin VALUES ('run-ok','%s'),('run-bad','%s')" % (P1, P2))
dec("run-ok", "2026-07-01T10:00:00Z", decision="allow", skill="cws:demo", perk="one",
    principal="auditor-fixture", destructive=False, plan_sha=P1)
ev("run-ok", 1, "2026-07-01T10:00:05Z", P1, type="step_result", step="1", status="ok", exit=0)
dec("run-bad", "2026-07-02T10:00:00Z", decision="allow", skill="cws:demo", perk="two",
    principal="auditor-fixture", destructive=True, approved=["two"], plan_sha=P2)
ev("run-bad", 1, "2026-07-02T10:00:05Z", P2, type="step_result", step="1", status="error", exit=1)
dec("run-rej", "2026-07-03T10:00:00Z", decision="reject", skill="cws:demo", perk="three",
    principal="auditor-fixture", destructive=False)
ev("run-tam", 1, "2026-07-04T10:00:00Z", P1, type="tamper_refused")
cx.commit()
cx.close()

bl = {"chain": "backup-ledger", "schema": ledger.CURRENT_MAJOR,
      "entries": [ledger.genesis("backup-ledger",
                  hashlib.sha256(b"cws-backup/double:generation-zero").hexdigest())]}
ledger.append(bl["entries"], {"ts": "2026-07-05T03:30:00Z", "stamp": "2026-07-05T033000Z",
                              "scope": "fixture", "files": 3, "bytes": 1234,
                              "manifest_sha": "c" * 64, "db": "fixture"}, bl["schema"])
json.dump(bl, open(os.path.join(here, "backup-ledger.json"), "w"), indent=2)
print("fixture written")
