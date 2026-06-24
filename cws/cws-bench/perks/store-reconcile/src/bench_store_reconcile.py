#!/usr/bin/env python3
"""bench_store_reconcile — P5-T01 validator (validated_by cws-bench). Proves end to end:
  (a) both_adapters_pass — the sqlite-WAL backend AND (if a live DSN is wired) the psycopg/Postgres backend
      pass ONE identical contract suite (store_selftest), and the inert-until-configured path holds;
  (b) soak_zero_divergence — a soak holds zero divergence between the chained-JSONL artifact of record and the
      derived index;
  (c) injected_divergence_caught — one injected index mutation alarms within ONE reconcile cycle.
Writes reconcile.json; exits 0 iff `within`. The Postgres leg is HONEST: `psycopg_live` records live | skipped
| error so an absent Postgres is visible, never silently counted as a live pass."""
import json
import os
import sys
import tempfile

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "store")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.store import backend as B          # noqa: E402
from infra.store import chainstore            # noqa: E402
from infra.store import reconcile             # noqa: E402


def _intenv(key, default):
    try:
        return int(os.environ.get(key, ""))
    except (TypeError, ValueError):
        return default


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    n_ops = _intenv("N_OPS", 2000)
    soak_cycles = _intenv("SOAK_CYCLES", 20)

    # (a) the SAME contract suite on each adapter. sqlite ALWAYS; the live Postgres leg runs iff a DSN is
    #     wired — via GOVD_STORE_DSN[_FILE], else an OPERATOR well-known file (~/.cyberware/store-dsn, the
    #     server-side key_file pattern: the secret never crosses the governed env as a var). HONEST reporting:
    #     `both_adapters_pass` is true ONLY when the live Postgres leg actually ran and passed; a skip is NOT a
    #     pass. The inert-until-configured path is always exercised inside store_selftest.
    sqlite_ok = B.store_selftest()["ok"]
    pg_live = "skipped"
    dsn, dsn_file = os.environ.get("GOVD_STORE_DSN"), os.environ.get("GOVD_STORE_DSN_FILE")
    if not (dsn or dsn_file):
        wk = os.path.expanduser("~/.cyberware/store-dsn")       # operator-wired, server-side (like a key_file)
        if os.path.isfile(wk):
            dsn_file = wk
    if dsn or dsn_file:
        try:
            import psycopg  # noqa: F401
            be_pg = B.PsycopgBackend({"dsn": dsn} if dsn else {"dsn_file": dsn_file}).open()
            be_pg.reset()
            pg_live = "live" if B.store_selftest(backend_factory=lambda: be_pg)["ok"] else "live-failed"
        except Exception as e:
            pg_live = f"error:{type(e).__name__}"
    # both adapters genuinely exercised + passed (the strong claim); a skip is honestly NOT both_adapters_pass
    both_adapters_pass = bool(sqlite_ok and pg_live == "live")
    pg_not_failed = pg_live in ("live", "skipped")              # within tolerates an honest skip; never a failure

    # (b) soak: a writer drives chain + index in lockstep; the reconciler holds zero divergence
    d = tempfile.mkdtemp(prefix="bench-store-")
    be = B.SqliteWalBackend(os.path.join(d, "i.sqlite")).open()
    cs = chainstore.ChainStore(d)
    rid, plan = "soak", "soak-plan"
    be.set_origin(rid, plan)
    for i in range(n_ops):
        rec = cs.append_record(rid, plan, "event", {"ts": f"t{i}", "step": i, "status": "ok"})
        c = chainstore.record_columns(rec)
        be.index_record(c["run_id"], c["seq"], c["prev"], c["link_digest"], c["kind"], c["ts"],
                        c["plan_sha"], c["fields"])
    soak = reconcile.continuous_reconcile(be, d, interval=0, cycles=soak_cycles)
    soak_zero_divergence = soak["divergence_seen"] is False

    # (c) inject ONE divergence (tamper a digest cell mid-chain) -> the NEXT cycle alarms
    be.cx.execute("UPDATE idx_record SET link_digest='tampered' WHERE run_id=? AND seq=?", (rid, n_ops // 2))
    after = reconcile.continuous_reconcile(be, d, interval=0, cycles=1)
    injected_divergence_caught = after["divergence_seen"] is True
    cycles_to_alarm = (after["first_alarm_cycle"] + 1) if after["first_alarm_cycle"] is not None else 0

    # `within` (the perk verdict) requires sqlite + the reconciler properties + the live Postgres leg not
    # FAILING. A clean skip (no DSN, e.g. in CI) keeps within=true on sqlite + inert; `both_adapters_pass`
    # separately records whether the LIVE Postgres adapter was also proven (the redemption wires it; see below).
    within = bool(sqlite_ok and pg_not_failed and soak_zero_divergence and injected_divergence_caught
                  and cycles_to_alarm == 1)
    r = {"within": within, "both_adapters_pass": both_adapters_pass, "sqlite_ok": sqlite_ok,
         "psycopg_live": pg_live, "soak_zero_divergence": soak_zero_divergence, "soak_cycles": soak_cycles,
         "soak_note": f"representative {soak_cycles}-cycle / {n_ops}-op window, not the production 1M-entry soak",
         "injected_divergence_caught": injected_divergence_caught, "cycles_to_alarm": cycles_to_alarm,
         "n_ops": n_ops}
    with open(os.path.join(store, "reconcile.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "bench_store_reconcile", "within": within, "psycopg_live": pg_live}))
    sys.exit(0 if within else 1)


if __name__ == "__main__":
    main()
