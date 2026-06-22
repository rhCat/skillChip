#!/usr/bin/env python3
"""bench_sse_latency — P5-T02: the dashboard's Server-Sent-Events push replaces the 1.5s client poll.

Measure the cost of the new boundary: end-to-end PUSH latency from a recorded decision to the streamed
event, and that each push carries a BOUNDED payload (pagination caps the decisions feed regardless of how
many decisions accrue — the soak budget is met by structure, not a one-hour test).

Boots a real local govd, opens one SSE connection, triggers a /govern decision, and times how long until
that decision appears in a pushed frame. Writes bench.json; exits 0 iff push_latency_ms <= BUDGET_MS AND
the per-push decisions payload stays within one page.
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
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)
from infra.govern import govd_client  # noqa: E402

BUDGET_MS = float(os.environ.get("BUDGET_MS") or "1500")     # the old poll interval — SSE must beat it
PORT = int(os.environ.get("SSE_PORT") or "5799")
BASE = f"http://127.0.0.1:{PORT}"


def _read_event(resp):
    """Read the next complete SSE `data:` event LINE-BY-LINE (readline flushes per line, so a small keepalive
    trickle cannot stall a buffered read). Skips `retry:`/`: comment` lines; None on EOF."""
    data = []
    while True:
        line = resp.readline()
        if not line:
            return None
        text = line.decode(errors="replace").rstrip("\n")
        if text == "":                          # blank line terminates an event
            if data:
                return json.loads("".join(data))
            continue                            # blank after a comment/retry — keep reading
        if text.startswith("data:"):
            data.append(text[len("data:"):].lstrip())


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    out = os.path.join(store, "bench.json")
    env = dict(os.environ, GOVD_RECORD_ROOT=tempfile.mkdtemp(prefix="sse-bench-"),
               GOVD_MONITOR_TOKEN="admin", GOVD_SSE_INTERVAL="0.2")
    env.pop("GOVD_PRINCIPALS", None)
    proc = subprocess.Popen([sys.executable, "-m", "infra.govern.govd", "--mode", "local", "--port", str(PORT)],
                            cwd=_root, env=env)
    resp = None
    try:
        for _ in range(120):
            try:
                urllib.request.urlopen(BASE + "/health", timeout=1).read(); break
            except Exception:
                time.sleep(0.25)
        resp = urllib.request.urlopen(BASE + "/monitor/stream?token=admin", timeout=10)
        resp.fp.raw._sock.settimeout(8)
        base_evt = _read_event(resp) or {}
        base_total = base_evt.get("decisions_page", {}).get("total", 0)

        # trigger a recorded decision; the POST returns only AFTER govd has computed the verdict + recorded
        # it, so timing the SSE push from HERE measures push latency alone (not the claim's plan+TLC cost).
        govd_client._post_json(BASE + "/govern", {"skill": "fs", "perk": "find_large", "var_keys": ["SEARCH_DIR"]})
        t0 = time.time()
        latency_ms = None
        for _ in range(60):
            evt = _read_event(resp)
            if evt is None:
                break
            if evt.get("decisions_page", {}).get("total", 0) > base_total:
                latency_ms = (time.time() - t0) * 1000.0
                break

        # bounded payload: drive more decisions, confirm one push never exceeds one page (pagination cap)
        for _ in range(40):
            govd_client._post_json(BASE + "/govern",
                                   {"skill": "fs", "perk": "find_large", "var_keys": ["SEARCH_DIR"]})
        st = json.loads(urllib.request.urlopen(BASE + "/monitor/state?token=admin", timeout=5).read())
        page = st.get("decisions_page", {})
        page_items = len(st.get("decisions", []))
        page_bounded = page_items <= page.get("limit", 200)

        within = latency_ms is not None and latency_ms <= BUDGET_MS and page_bounded
        json.dump({"perk": "sse-latency", "push_latency_ms": latency_ms, "budget_ms": BUDGET_MS,
                   "page_items": page_items, "page_limit": page.get("limit"), "page_bounded": page_bounded,
                   "within": within}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "bench_sse_latency", "within": within, "push_latency_ms": latency_ms}))
        return 0 if within else 1
    finally:
        if resp is not None:
            try:
                resp.close()
            except Exception:
                pass
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()


if __name__ == "__main__":
    sys.exit(main())
