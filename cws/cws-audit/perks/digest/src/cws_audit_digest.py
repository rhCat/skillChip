#!/usr/bin/env python3
"""cws_audit_digest — render the node's governed history as a HUMAN-readable audit digest.

The machine records are complete but unreadable at review speed: chained store rows, per-run
ledgers, a backup chain. This perk digests them for a HUMAN auditor: one Markdown report
(`audit.md`) answering the audit questions in order — what ran (by skill/perk, with step yield),
what was REFUSED (rejects + in-channel tamper/oversight refusals, each named), who acted
(principals), whether anything destructive was approved, and whether the durability leg is honest
(backup chain re-verified, last verified double named). Every section carries the drill-down keys
(run_ids, plan_shas, chain heads) so a finding is checkable against the tamper-evident record —
the digest SUMMARIZES evidence, it never replaces it. `audit.json` carries the same numbers for
machines. Strictly read-only (sqlite opened mode=ro; a postgresql:// DSN reads the same SQL).

Reads from env: LEDGER_DB (required — a WAL-safe SNAPSHOT of the store index, or a DSN), SINCE /
UNTIL (optional ISO-8601 window), BACKUP_LEDGER (optional path to a cws-backup backup-ledger.json
to re-verify + report), SCOPE (report label; default the ledger filename), TOP (default 10 rows in
per-skill tables), RECORD_STORE. Exit 0 on a rendered digest (an empty window is a valid, stated
answer); nonzero fail-closed on a missing/unreadable store."""
from __future__ import annotations
import hashlib
import json
import os
import sys

# locate the cyberware repo root so the backup chain can be RE-VERIFIED (not just displayed)
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

REFUSAL_EVENTS = {"tamper_refused", "oversight_refused"}


def open_store(target):
    if target.startswith(("postgresql://", "postgres://")) or target.startswith("dbname="):
        import psycopg
        return psycopg.connect(target, autocommit=True), "postgres"
    if not os.path.isfile(target):
        raise FileNotFoundError(f"ledger store not a file: {target}")
    import sqlite3
    return sqlite3.connect(f"file:{os.path.abspath(target)}?mode=ro", uri=True), "sqlite"


def in_window(ts, since, until):
    if not ts:
        return True
    return (not since or ts >= since) and (not until or ts <= until)


def gather(cx, since, until):
    """One pass over the three index tables into the audit aggregates."""
    origins = {r[0]: r[1] for r in cx.execute("SELECT run_id, plan_sha FROM idx_origin")}
    agg = {"runs": set(), "decisions": {}, "destructive": [], "rejected": [], "principals": {},
           "by_skill": {}, "steps": {"ok": 0, "fail": 0}, "failed_steps": [], "refusals": [],
           "first_ts": None, "last_ts": None}

    def touch(ts):
        if ts:
            agg["first_ts"] = ts if agg["first_ts"] is None else min(agg["first_ts"], ts)
            agg["last_ts"] = ts if agg["last_ts"] is None else max(agg["last_ts"], ts)

    dec_by_run = {}
    for run_id, ts, fields in cx.execute("SELECT run_id, ts, fields FROM idx_decision"):
        if not in_window(ts, since, until):
            continue
        f = json.loads(fields or "{}")
        dec_by_run.setdefault(run_id, f)
        agg["runs"].add(run_id)
        touch(ts)
        verdict = f.get("decision") or "(none)"
        agg["decisions"][verdict] = agg["decisions"].get(verdict, 0) + 1
        skill = f"{f.get('skill') or '?'}/{f.get('perk') or '?'}"
        row = agg["by_skill"].setdefault(skill, {"runs": 0, "ok": 0, "fail": 0})
        row["runs"] += 1
        if f.get("principal"):
            agg["principals"][f["principal"]] = agg["principals"].get(f["principal"], 0) + 1
        if f.get("destructive"):
            agg["destructive"].append({"run_id": run_id, "ts": ts, "skill": skill,
                                       "approved": f.get("approved") or f.get("needs_approve")})
        if verdict != "allow":
            agg["rejected"].append({"run_id": run_id, "ts": ts, "skill": skill, "decision": verdict})

    for run_id, ts, plan_sha, fields in cx.execute("SELECT run_id, ts, plan_sha, fields FROM idx_record"):
        if not in_window(ts, since, until):
            continue
        f = json.loads(fields or "{}")
        etype = f.get("type")
        if etype in REFUSAL_EVENTS:
            agg["refusals"].append({"run_id": run_id, "ts": ts, "type": etype,
                                    "plan_sha": (plan_sha or "")[:12]})
            touch(ts)
        if etype != "step_result":
            continue
        agg["runs"].add(run_id)
        touch(ts)
        skill = "?"
        d = dec_by_run.get(run_id)
        if d:
            skill = f"{d.get('skill') or '?'}/{d.get('perk') or '?'}"
        row = agg["by_skill"].setdefault(skill, {"runs": 0, "ok": 0, "fail": 0})
        ok = f.get("status") == "ok"
        agg["steps"]["ok" if ok else "fail"] += 1
        row["ok" if ok else "fail"] += 1
        if not ok:
            agg["failed_steps"].append({"run_id": run_id, "ts": ts, "skill": skill,
                                        "step": f.get("step"), "exit": f.get("exit"),
                                        "plan_sha": (origins.get(run_id) or "")[:12]})
    return agg


def backup_section(path):
    """Re-verify the backup chain and report the LAST verified double — the durability answer."""
    led = json.load(open(path))
    entries = led.get("entries", [])
    try:
        from infra.cwp.chainverify import verify_chain
        ok, bad = verify_chain(entries, led.get("schema", 2))
        chain = "VERIFIED" if ok else f"BROKEN ({len(bad)} bad records)"
    except Exception as e:
        chain = f"unverifiable here ({type(e).__name__})"
    last = next((e for e in reversed(entries) if e.get("type") != "genesis"), None)
    head = hashlib.sha256(json.dumps(entries[-1], sort_keys=True).encode()).hexdigest()[:16] if entries else None
    rec = (last or {}).get("fields") or last or {}
    return {"path": path, "entries": len(entries), "chain": chain, "head": head,
            "last": {k: rec.get(k) for k in ("ts", "stamp", "scope", "files", "bytes", "manifest_sha")}
            if last else None}


def render_md(scope, window, agg, backup, backend):
    n_runs = len(agg["runs"])
    lines = [f"# Governed-run audit digest — {scope}", ""]
    lines += [f"- **Window**: {window[0] or 'beginning'} → {window[1] or 'now'} "
              f"(activity seen {agg['first_ts'] or '—'} → {agg['last_ts'] or '—'})",
              f"- **Store**: {backend} (read-only)", ""]
    if n_runs == 0:
        lines += ["**No governed activity in this window.**", ""]
    dec = ", ".join(f"{k}: {v}" for k, v in sorted(agg["decisions"].items())) or "—"
    lines += ["## Activity", "",
              f"- Runs: **{n_runs}** · Decisions: {dec}",
              f"- Steps: **{agg['steps']['ok']} ok / {agg['steps']['fail']} failed**",
              f"- Principals: " + (", ".join(f"{k} ({v})" for k, v in
                                             sorted(agg["principals"].items(), key=lambda x: -x[1])) or "—"), ""]
    top = int(os.environ.get("TOP") or "10")
    rows = sorted(agg["by_skill"].items(), key=lambda x: -x[1]["runs"])[:top]
    if rows:
        lines += ["## By skill/perk (top by runs)", "", "| skill/perk | runs | steps ok | steps failed |",
                  "|---|---|---|---|"]
        lines += [f"| {k} | {v['runs']} | {v['ok']} | {v['fail']} |" for k, v in rows]
        lines.append("")
    lines += ["## Refusals & rejections — the gate record", ""]
    if not agg["rejected"] and not agg["refusals"]:
        lines += ["None in this window.", ""]
    for r in agg["rejected"]:
        lines.append(f"- `{r['ts']}` **{r['decision']}** — {r['skill']} (run `{r['run_id']}`)")
    for r in agg["refusals"]:
        lines.append(f"- `{r['ts']}` **{r['type']}** — run `{r['run_id']}` plan `{r['plan_sha']}`")
    if agg["rejected"] or agg["refusals"]:
        lines.append("")
    lines += ["## Destructive approvals", ""]
    lines += [f"- `{d['ts']}` {d['skill']} (run `{d['run_id']}`, approved: {d['approved']})"
              for d in agg["destructive"]] or ["None in this window."]
    lines.append("")
    if agg["failed_steps"]:
        lines += ["## Failed steps (drill-down keys)", ""]
        lines += [f"- `{s['ts']}` {s['skill']} step {s['step']} exit {s['exit']} "
                  f"(run `{s['run_id']}`, plan `{s['plan_sha']}`)" for s in agg["failed_steps"][:top]]
        if len(agg["failed_steps"]) > top:
            lines.append(f"- … and {len(agg['failed_steps']) - top} more (see audit.json)")
        lines.append("")
    lines += ["## Durability (backup chain)", ""]
    if backup:
        last = backup["last"] or {}
        lines += [f"- Chain: **{backup['chain']}** · entries: {backup['entries']} · head `{backup['head']}`",
                  f"- Last double: `{last.get('stamp') or last.get('ts') or '—'}` — "
                  f"{last.get('files', '—')} files / {last.get('bytes', '—')} bytes "
                  f"(manifest `{str(last.get('manifest_sha') or '')[:16]}`)", ""]
    else:
        lines += ["Not checked (no BACKUP_LEDGER provided).", ""]
    lines += ["---", "*This digest summarizes the tamper-evident record; every claim above is",
              "checkable by run_id / plan_sha against the store and per-run chains.*", ""]
    return "\n".join(lines)


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out_json, out_md = os.path.join(store, "audit.json"), os.path.join(store, "audit.md")
    os.makedirs(store, exist_ok=True)

    def refuse(reason):
        json.dump({"tool": "cws_audit_digest", "verdict": "refused", "reason": reason},
                  open(out_json, "w"), indent=2)
        print(json.dumps({"tool": "cws_audit_digest", "verdict": "refused", "reason": reason,
                          "report": out_json}))
        return 1

    target = (os.environ.get("LEDGER_DB") or "").strip()
    if not target:
        return refuse("LEDGER_DB is required — a snapshot of the store index, or a DSN")
    since = (os.environ.get("SINCE") or "").strip() or None
    until = (os.environ.get("UNTIL") or "").strip() or None
    scope = (os.environ.get("SCOPE") or os.path.basename(target)).strip()
    backup_path = (os.environ.get("BACKUP_LEDGER") or "").strip()

    try:
        cx, backend = open_store(target)
        agg = gather(cx, since, until)
        cx.close()
    except Exception as e:
        return refuse(f"{type(e).__name__}: {e}")
    backup = None
    if backup_path:
        try:
            backup = backup_section(backup_path)
        except Exception as e:
            return refuse(f"BACKUP_LEDGER unreadable: {type(e).__name__}: {e}")

    md = render_md(scope, (since, until), agg, backup, backend)
    open(out_md, "w", encoding="utf-8").write(md)
    summary = {"tool": "cws_audit_digest", "verdict": "ok", "scope": scope, "backend": backend,
               "window": {"since": since, "until": until},
               "runs": len(agg["runs"]), "decisions": agg["decisions"], "steps": agg["steps"],
               "principals": agg["principals"], "rejected": agg["rejected"],
               "refusals": agg["refusals"], "destructive": agg["destructive"],
               "failed_steps": agg["failed_steps"], "by_skill": agg["by_skill"],
               "backup": backup, "report_md": out_md}
    json.dump(summary, open(out_json, "w"), indent=2)
    print(json.dumps({"tool": "cws_audit_digest", "verdict": "ok", "runs": len(agg["runs"]),
                      "steps": agg["steps"], "rejected": len(agg["rejected"]),
                      "refusals": len(agg["refusals"]),
                      "backup_chain": (backup or {}).get("chain"), "report": out_md}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
