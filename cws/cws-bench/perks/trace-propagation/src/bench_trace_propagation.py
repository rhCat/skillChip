#!/usr/bin/env python3
"""bench_trace_propagation — P5-T05: a governed run carries ONE W3C trace id across planes.

Boots a real local govd, drives a benign governed run (cws-ledgercheck/principal) with an agent-supplied
traceparent, then retrieves the run BY run_id: the cross-plane trace (claim→grant→step spans, all under one
trace id) via /trace/<id>, and the in-toto cyberware/run@v1 attestation via /intoto/<id>. Writes trace.json;
exits 0 iff the trace is retrievable, the trace id is consistent across the planes, and the attestation is
well-formed.
"""
from __future__ import annotations
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.request

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)
from infra.govern import govd_client  # noqa: E402
from infra.govern import tracing      # noqa: E402

PORT = int(os.environ.get("TRACE_PORT") or "5797")
BASE = f"http://127.0.0.1:{PORT}"


def _get(path):
    return json.loads(urllib.request.urlopen(BASE + path, timeout=5).read())


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    out = os.path.join(store, "trace.json")
    env = dict(os.environ, GOVD_RECORD_ROOT=tempfile.mkdtemp(prefix="trace-bench-"), GOVD_MONITOR_TOKEN="admin")
    env.pop("GOVD_PRINCIPALS", None)
    proc = subprocess.Popen([sys.executable, "-m", "infra.govern.govd", "--mode", "local", "--port", str(PORT)],
                            cwd=_root, env=env)
    try:
        for _ in range(120):
            try:
                urllib.request.urlopen(BASE + "/health", timeout=1).read(); break
            except Exception:
                time.sleep(0.25)
        tp = tracing.new_traceparent()
        want_trace = tracing.parse_traceparent(tp)["trace_id"]
        led = {"skill": "cws-ledgercheck", "perk": "principal",
               "record_store": os.path.join(store, "run"), "vars": {}, "traceparent": tp}
        r = govd_client.run_governed(BASE, led)
        run_id = r.get("run_id")
        ran_ok = r.get("decision") == "allow" and [s.get("exit") for s in r.get("results", [])] == [0]

        trace = _get("/trace/" + run_id + "?token=admin")
        planes = [s.get("plane") for s in trace.get("spans", [])]
        retrievable = bool(trace.get("trace_id")) and "claim" in planes and "granted" in planes \
            and "step_result" in planes
        # the SAME trace id flows claim→grant→step (the agent's traceparent), every hop has a span
        trace_consistent = trace.get("trace_id") == want_trace and all(s.get("span_id") for s in trace["spans"])

        att = _get("/intoto/" + run_id + "?token=admin")
        intoto_ok = (att.get("_type") == "https://in-toto.io/Statement/v1"
                     and att.get("predicateType") == tracing.CWRUN_PREDICATE
                     and att.get("predicate", {}).get("trace_id") == want_trace
                     and len(att.get("predicate", {}).get("steps", [])) >= 1)

        ok = ran_ok and retrievable and trace_consistent and intoto_ok
        json.dump({"perk": "trace-propagation", "run_id": run_id, "trace_id": want_trace, "planes": planes,
                   "ran_ok": ran_ok, "retrievable": retrievable, "trace_consistent": trace_consistent,
                   "intoto_ok": intoto_ok, "ok": ok}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "bench_trace_propagation", "ok": ok, "planes": planes}))
        return 0 if ok else 1
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()


if __name__ == "__main__":
    sys.exit(main())
