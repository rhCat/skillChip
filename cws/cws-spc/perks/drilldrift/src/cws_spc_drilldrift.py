#!/usr/bin/env python3
"""cws_spc_drilldrift — the SPC oracle drill: the drift alarm must FIRE on a seeded regression and
STAY SILENT on a benign series (P0.5 acceptance).

A drift detector that never alarms is useless; one that always alarms is noise. This drill proves both
poles against the same calibrated envelope: the SEEDED series (a planted regression) must raise the
3-sigma alarm, and the BENIGN series must not. Exit 0 iff BOTH behave. The check logic is duplicated
from the chart perk on purpose — each perk closure is self-contained (no cross-perk sourcing inside the
sandbox); duplication is the price of confinement.

Reads SEEDED, BENIGN, ENVELOPE (each defaulting to the bundled fixture), SIGMA_K (default 3) +
RECORD_STORE from env; writes RECORD_STORE/drilldrift.json + one structured JSON line. Stdlib only.
"""
from __future__ import annotations
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = os.path.join(os.path.dirname(HERE), "test", "fixture")


def alarms_in(series_path, env, k):
    """The detectors whose series breach mean +/- k*sigma under the calibrated envelope."""
    d = json.load(open(series_path))
    d = d.get("series", d) if isinstance(d, dict) else d
    out = []
    for name, values in sorted(d.items()):
        if not isinstance(values, list) or name not in env:
            continue
        mu, sd = float(env[name]["mean"]), float(env[name]["sigma"])
        ucl, lcl = mu + k * sd, mu - k * sd
        if any(float(v) > ucl or float(v) < lcl for v in values):
            out.append(name)
    return out


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "drilldrift.json")
    os.makedirs(store, exist_ok=True)
    seeded = os.environ.get("SEEDED") or os.path.join(FIXTURE, "seeded.json")
    benign = os.environ.get("BENIGN") or os.path.join(FIXTURE, "benign.json")
    env_path = os.environ.get("ENVELOPE") or os.path.join(FIXTURE, "envelope.json")
    k = float(os.environ.get("SIGMA_K") or "3")

    env = json.load(open(env_path))
    seeded_alarms = alarms_in(seeded, env, k)
    benign_alarms = alarms_in(benign, env, k)
    legs = {"seeded": "alarmed" if seeded_alarms else "MISSED",
            "benign": "clean" if not benign_alarms else "FALSE-ALARM"}
    ok = bool(seeded_alarms) and not benign_alarms
    report = {"tool": "cws_spc_drilldrift", "ok": ok, "status": "ok" if ok else "fail",
              "legs": legs, "seeded_alarms": seeded_alarms, "benign_alarms": benign_alarms,
              "sigma_k": k,
              "oracle": "seeded regression alarms; benign series stays clean — both poles or the drill fails"}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_spc_drilldrift", "ok": ok, "legs": legs, "report": out}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
