#!/usr/bin/env python3
"""cws_torture — durability torture for the Ledger-v2 chain (P1-T09 / SV-2).

Spawns N concurrent writers that each `durable_append` to one chain (the harness promoted from P1-T02,
infra.cwp.torture), then asserts the result is ONE valid prev-hash chain: zero lost, every line parses,
verify_chain ok, contiguous seq. This is the durability acceptance made into a governed perk — running it
THROUGH the executor records its own run-ledger, which cws-ledgercheck/verify can then re-verify (the
recursive SV-2 twist).

env: RECORD_STORE; optional CHAIN_PATH (default RECORD_STORE/torture-chain.jsonl), WORKERS (default 8),
APPENDS_PER (default 200). Writes RECORD_STORE/torture.json + one structured JSON line. Exit 0 iff the
concurrent writers serialized into a single sound chain with zero loss.
"""
from __future__ import annotations
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "cwp"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "cwp")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "cwp")):
    sys.path.insert(0, _root)

from infra.cwp import torture as _t  # noqa: E402


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "torture.json")
    os.makedirs(store, exist_ok=True)
    chain = os.environ.get("CHAIN_PATH") or os.path.join(store, "torture-chain.jsonl")
    if os.path.exists(chain):
        os.remove(chain)
    cfg = _t.TortureConfig(workers=int(os.environ.get("WORKERS", "8")),
                           appends_per=int(os.environ.get("APPENDS_PER", "200")))
    report, _entries = _t.run_concurrent_torture(chain, cfg)
    ok = (report["lost"] == 0 and report["all_parse"] and report["verify_chain_ok"]
          and report["seqs_contiguous"] and report["entry_count"] == report["total_expected"])
    report["status"] = "ok" if ok else "fail"
    report["chain_path"] = chain
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_torture", "status": report["status"], "workers": cfg.workers,
                      "entries": report["entry_count"], "lost": report["lost"], "report": out}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
