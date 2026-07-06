#!/usr/bin/env python3
"""cws_spc_chart — statistical process control over calibrated detector envelopes (P0.5).

An instrument is only trustworthy while it stays inside its calibrated envelope. This reads a
TIME-SERIES of measurements per detector (e.g. FA/kfn per run) and an ENVELOPE (calibrated mean/sigma
per detector), draws the control chart (center line + UCL/LCL at SIGMA_K sigma), and raises a
3-sigma-style DRIFT ALARM for any point outside the limits. When no envelope is supplied, the first
BASELINE_N points self-calibrate one (recorded as source: baseline, honestly distinct from a
calibrated reference). The gate IS the exit code: 0 in-control, 1 drift.

Reads SERIES (+ optional ENVELOPE, SIGMA_K [default 3], BASELINE_N [default 8]) + RECORD_STORE from
env; writes RECORD_STORE/spc.json (the chart artifact) + one structured JSON line. Stdlib only.
"""
from __future__ import annotations
import json
import os
import statistics
import sys


def load_series(path):
    """Load the series file: {detector: [values]} (or wrapped in {"series": {...}})."""
    d = json.load(open(path))
    d = d.get("series", d) if isinstance(d, dict) else d
    return {k: [float(x) for x in v] for k, v in d.items() if isinstance(v, list)}


def envelope_for(values, env, name, baseline_n):
    """The detector's envelope: the CALIBRATED reference when given, else self-calibrated from the
    first baseline_n points (source recorded honestly)."""
    if env and name in env:
        e = env[name]
        return float(e["mean"]), float(e["sigma"]), "calibrated"
    base = values[:baseline_n]
    mu = statistics.fmean(base)
    sd = statistics.stdev(base) if len(base) > 1 else 0.0
    return mu, sd, "baseline"


def chart(values, mu, sd, k):
    """One detector's control chart: limits + every point outside them (the 3-sigma-style rule)."""
    ucl, lcl = mu + k * sd, mu - k * sd
    breaches = [{"i": i, "value": v} for i, v in enumerate(values) if v > ucl or v < lcl]
    return {"n": len(values), "mean": mu, "sigma": sd, "ucl": ucl, "lcl": lcl,
            "breaches": breaches, "in_control": not breaches}


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "spc.json")
    os.makedirs(store, exist_ok=True)
    series_path = os.environ.get("SERIES", "")
    k = float(os.environ.get("SIGMA_K") or "3")
    baseline_n = int(os.environ.get("BASELINE_N") or "8")

    def emit(obj, code):
        json.dump(obj, open(out, "w"), indent=2)
        line = {kk: obj[kk] for kk in ("tool", "status", "detectors", "alarms", "reason") if kk in obj}
        print(json.dumps({**line, "report": out}))
        return code

    if not series_path or not os.path.isfile(series_path):
        return emit({"tool": "cws_spc_chart", "status": "fail", "reason": f"SERIES not a file: {series_path}"}, 1)
    series = load_series(series_path)
    if not series:
        return emit({"tool": "cws_spc_chart", "status": "fail", "reason": "SERIES carries no detector series"}, 1)
    env_path = os.environ.get("ENVELOPE", "")
    env = json.load(open(env_path)) if env_path and os.path.isfile(env_path) else None

    charts, alarms = {}, []
    for name, values in sorted(series.items()):
        mu, sd, source = envelope_for(values, env, name, baseline_n)
        c = chart(values, mu, sd, k)
        c["envelope_source"] = source
        charts[name] = c
        if not c["in_control"]:
            alarms.append(name)

    status = "ok" if not alarms else "drift"
    report = {"tool": "cws_spc_chart", "status": status, "sigma_k": k,
              "detectors": len(charts), "alarms": alarms, "charts": charts}
    return emit(report, 0 if status == "ok" else 1)


if __name__ == "__main__":
    sys.exit(main())
