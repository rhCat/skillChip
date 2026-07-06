#!/usr/bin/env python3
"""cws_qualify_coupon — grade a performer lot's coupon run and write its Q-RECORD (Q1).

The Q-ladder rule: a lot EARNS standing; it is never asserted. The lot is the EXAMINEE — it runs the
coupon tasks through the governed channel elsewhere; this perk only MEASURES the yield from that
evidence (the governed run-ledgers, never self-report): first-pass rate, scrap rate, and iteration
economy (mean attempts per passed coupon). A passing yield appends a prev-hash-chained Q-RECORD keyed
by the lot hash — `{seq, ts, lot, rung, scope, coupons, first_pass, scrap, attempts_mean, verdict,
evidence_sha, prev}` — to the Q-ledger, the record an ACL grant can later cross-reference (Q2: scope
granted = scope earned).

COUPONS is the coupon manifest: `[{coupon_id, skill, perk, attempts: [run-ledger paths, in order]}]` —
each attempt a governed run-ledger (govd events[] or executor runs[] shape). first_pass = attempt 1
passed; scrap = no attempt passed; a scrapped coupon refuses the whole record (fail-closed).

Reads PERFORMER_LOT, COUPONS (+ optional RUNG [executor], SCOPE, MIN_FIRST_PASS [0.8], Q_LEDGER
[RECORD_STORE/q-ledger.json]) + RECORD_STORE from env; writes RECORD_STORE/coupon.json + one JSON
line. Exit 0 iff the yield qualifies, else 1.
"""
from __future__ import annotations
import hashlib
import json
import os
import sys
import time

# locate the cyberware repo root so we can import the shared, schema-aware ledger-digest helper
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra.cwp import ledger  # noqa: E402

REFUSAL_EVENTS = {"tamper_refused", "oversight_refused"}


def run_ledger_passed(rl):
    """A governed run-ledger evidences a clean pass (govd events[] or executor runs[] shape) —
    the same evidence bar cws-observe/redeem holds (duplicated: perk closures are self-contained)."""
    if isinstance(rl, dict) and "events" in rl:
        if rl.get("decision") != "allow":
            return False
        evs = rl["events"]
        if any(e.get("type") in REFUSAL_EVENTS for e in evs):
            return False
        results = [e for e in evs if e.get("type") == "step_result"]
        return bool(results) and all(e.get("status") == "ok" for e in results)
    runs = (rl or {}).get("runs")
    if not isinstance(runs, list):
        return False
    steps = [r for r in runs if "step" in r and "event" not in r]
    if any(r.get("event") in REFUSAL_EVENTS for r in runs):
        return False
    return bool(steps) and all(r.get("status") == "ok" for r in steps)


def grade(coupons, base):
    """Measure the yield over the coupon manifest: per-coupon first-pass / passed / attempts, and the
    roll-up (first_pass rate, scrap rate, mean attempts per passed coupon). Attempt paths are resolved
    relative to `base` (the manifest's directory) when not absolute."""
    rows, digests = [], []
    for c in coupons:
        attempts = c.get("attempts") or []
        verdicts = []
        for p in attempts:
            ok = False
            path = p if os.path.isabs(p) else os.path.join(base, p)
            if path and os.path.isfile(path):
                try:
                    ok = run_ledger_passed(json.load(open(path)))
                except Exception:
                    ok = False
                digests.append(hashlib.sha256(open(path, "rb").read()).hexdigest())
            verdicts.append(ok)
        first = bool(verdicts and verdicts[0])
        passed = any(verdicts)
        used = (verdicts.index(True) + 1) if passed else len(verdicts)
        rows.append({"coupon_id": c.get("coupon_id"), "skill": c.get("skill"), "perk": c.get("perk"),
                     "attempts": len(attempts), "first_pass": first, "passed": passed,
                     "attempts_to_pass": used if passed else None})
    n = len(rows)
    passed_rows = [r for r in rows if r["passed"]]
    yield_ = {"coupons": n,
              "first_pass": (sum(1 for r in rows if r["first_pass"]) / n) if n else 0.0,
              "scrap": (sum(1 for r in rows if not r["passed"]) / n) if n else 1.0,
              "attempts_mean": (sum(r["attempts_to_pass"] for r in passed_rows) / len(passed_rows))
              if passed_rows else None}
    evidence_sha = hashlib.sha256("\x00".join(sorted(digests)).encode()).hexdigest()
    return rows, yield_, evidence_sha


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "coupon.json")
    os.makedirs(store, exist_ok=True)
    lot = (os.environ.get("PERFORMER_LOT") or "").strip()
    coupons_path = os.environ.get("COUPONS", "")
    rung = (os.environ.get("RUNG") or "executor").strip()
    scope = (os.environ.get("SCOPE") or "").strip()
    min_first = float(os.environ.get("MIN_FIRST_PASS") or "0.8")
    q_ledger_path = os.environ.get("Q_LEDGER") or os.path.join(store, "q-ledger.json")

    def refuse(reason):
        json.dump({"tool": "cws_qualify_coupon", "verdict": "refused", "lot": lot, "reason": reason},
                  open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_qualify_coupon", "verdict": "refused", "reason": reason, "report": out}))
        return 1

    if not lot:
        return refuse("PERFORMER_LOT is required — a Q-record is keyed by the lot hash")
    if not coupons_path or not os.path.isfile(coupons_path):
        return refuse(f"COUPONS manifest not a file: {coupons_path}")
    manifest = json.load(open(coupons_path))
    coupons = manifest.get("coupons", manifest) if isinstance(manifest, dict) else manifest
    if not coupons:
        return refuse("the coupon manifest is empty — nothing measured, nothing earned")

    rows, y, evidence_sha = grade(coupons, os.path.dirname(os.path.abspath(coupons_path)))
    qualified = (y["scrap"] == 0.0) and (y["first_pass"] >= min_first)
    if not qualified:
        why = (f"scrap {y['scrap']:.2f} > 0" if y["scrap"] else
               f"first_pass {y['first_pass']:.2f} < required {min_first:.2f}")
        json.dump({"tool": "cws_qualify_coupon", "verdict": "refused", "lot": lot, "rung": rung,
                   "scope": scope, "yield": y, "coupon_rows": rows, "reason": why}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_qualify_coupon", "verdict": "refused", "lot": lot,
                          "yield": y, "reason": why, "report": out}))
        return 1

    if os.path.isfile(q_ledger_path):
        led = json.load(open(q_ledger_path))
    else:
        led = {"chain": "q-ledger", "schema": ledger.CURRENT_MAJOR,
               "entries": [{"type": "genesis", "schema": ledger.CURRENT_MAJOR, "prev": "0" * 64}]}
    entries = led.setdefault("entries", [])
    schema = led.get("schema", ledger.CURRENT_MAJOR)
    entry = {"seq": len(entries) + 1, "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
             "lot": lot, "rung": rung, "scope": scope, "coupons": y["coupons"],
             "first_pass": y["first_pass"], "scrap": y["scrap"], "attempts_mean": y["attempts_mean"],
             "verdict": "pass", "evidence_sha": evidence_sha, "prev": ledger.head_of(entries, schema)}
    entries.append(entry)
    os.makedirs(os.path.dirname(os.path.abspath(q_ledger_path)), exist_ok=True)
    ledger.write_object_atomic(q_ledger_path, led)

    json.dump({"tool": "cws_qualify_coupon", "verdict": "pass", "lot": lot, "rung": rung, "scope": scope,
               "yield": y, "coupon_rows": rows, "seq": entry["seq"], "q_ledger": q_ledger_path,
               "evidence_sha": evidence_sha}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_qualify_coupon", "verdict": "pass", "lot": lot, "rung": rung,
                      "yield": y, "seq": entry["seq"], "report": out}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
