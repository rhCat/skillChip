#!/usr/bin/env python3
"""Builds the fixture: a small index.sqlite (the real store schema shape) + a mirror tree standing
in for ~/.cyberware/fleet-ledgers (two nodes, a chain file each). Deterministic; re-run to regenerate."""
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
INSERT INTO idx_origin VALUES ('run-1', 'aaaa');
""")
cx.commit()
cx.close()

for node in ("node-a", "node-b"):
    d = os.path.join(here, "mirror", node)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "chain.jsonl"), "w") as f:
        f.write(json.dumps({"run_id": f"{node}-run", "seq": 0, "type": "genesis"}) + "\n")
print("fixture written")
