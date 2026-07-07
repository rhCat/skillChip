---
skill: cws-audit
name: Human Audit Digest
perks: [digest]
---

# cws-audit — the human face of the governed record

The machine record is complete but unreadable at review speed. `digest` turns a store-index
snapshot into **`audit.md`** — one report answering the audit questions in order: what ran (by
skill/perk with step yield), what was **refused** (rejects + in-channel tamper/oversight refusals,
each named), who acted (principals), what **destructive** work was approved, which steps failed
(with drill-down keys), and whether the durability leg is honest (the cws-backup chain
**re-verified**, not just displayed, and the last verified double named). `audit.json` carries the
same numbers for machines.

The digest SUMMARIZES evidence — it never replaces it: every line carries `run_id` / `plan_sha` /
chain-head keys so a human finding is checkable against the tamper-evident record. Strictly
read-only (sqlite `mode=ro`; a `postgresql://` DSN reads through the same SQL).

**Feed it a SNAPSHOT, never the live WAL file** — `VACUUM INTO` in the container, copy out (the
same discipline as `cws-ledgercheck/lotquery`).

## What to look out for
`audit.md` is the deliverable. An empty window renders "No governed activity" (a valid, stated
answer — exit 0). `refused` (exit 1) names the guard: missing/unreadable store, unreadable
BACKUP_LEDGER. A backup chain that fails recompute renders **BROKEN** in the Durability section —
that is a finding, not an error. LOGS TO CHECK: the JSON line + `audit.md` + this run's run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `digest` | `cws_audit_digest` | store-index snapshot (+ optional backup chain) → `audit.md` + `audit.json` — read-only / safe |

- **`digest`** — set `LEDGER_DB` (snapshot path or DSN). Optional: `SINCE`/`UNTIL` (ISO-8601
  window), `BACKUP_LEDGER` (a `cws-backup` chain to re-verify + report), `SCOPE` (report label),
  `TOP` (table rows, default 10).

## How to use it
Copy `ledger.json` → `task-ledger.json`, set `LEDGER_DB` + `record_store`, then claim it through
govd (or the local pipeline). Pair with `cws-backup/double` (whose share-side chain is the
`BACKUP_LEDGER` input) and `cws-ledgercheck/lotquery` (the per-lot drill-down the digest links to).
