---
skill: cws-backup
name: Governed-History Backup
perks: [double]
---

# cws-backup — Governed-History Backup (the 3-2-1 leg)

The per-node tamper-evident chains are the fleet's TRUTH; this skill is their durability leg. The
model: copy 1 = the node's local disk (the live store + the fleetdash mirror of every node's
value-free chains under `~/.cyberware/fleet-ledgers/`); copy 2 = the NAS share `double` writes;
copy 3 = the NAS's own cloud backup (off-site). The NAS mounts on the anchor tier only (mac/dgx/acer)
— edge nodes never touch it; their chains arrive via the mirror, which is exactly what `double`
sweeps. So one governed `double` run on the mac doubles the WHOLE fleet's chain history.

`double` snapshots the node's ledger DB **WAL-safely** (`VACUUM INTO` — never a raw copy of a live
WAL db; direct `LEDGER_DB` path, or inside the `CONTAINER` via docker), sweeps `SRC_DIRS` (default
the fleet-ledgers mirror), lands everything under `NAS_DIR/<SCOPE>/<UTC-stamp>/`, then **reads every
NAS byte back** and compares sha256 — a copy that doesn't verify is not a backup, and the run
refuses. Each verified run appends `{stamp, files, bytes, manifest_sha, db}` to a prev-hash-chained
`backup-ledger.json` ON the share (origin-bound genesis), so `cws-ledgercheck/verify` can re-verify
the backup history itself — and the share-side chain head is an external anchor for the node's own
ledger (a node can't quietly rewrite history whose digest lives on a share it doesn't control).

**Mount-down guard (fail-closed):** `NAS_DIR` must exist AND carry the operator-minted sentinel
`.cyberware-backup-target`. An unmounted mountpoint is just an empty local dir — writing there would
"succeed" while backing up nothing off-box. Mint the sentinel once, on the real share:
`touch <share>/.cyberware-backup-target`.

## What to look out for
`backup.json` carries `{verdict, files, bytes, verified, dest, manifest_sha, seq}`. `verdict: "ok"`
with `verified: true` is a clean double; `verify_failed` names each file whose read-back sha
mismatched; `refused` names the guard that stopped the run (no sentinel, unmounted share, missing
db, SRC_DIRS collision). LOGS TO CHECK: that line + `backup.json` + this run's own run-ledger.

## Perks
| perk | tool | nature |
|---|---|---|
| `double` | `cws_backup_double` | WAL-safe db snapshot + mirror sweep → NAS, read-back sha-verified, chained backup-ledger — writes only to `NAS_DIR/<SCOPE>/` + the record_store / safe |

- **`double`** — set `NAS_DIR` (the mounted share). Optional: `SCOPE` (share subdir; default
  hostname), `LEDGER_DB` (snapshot a db file directly — wins over docker mode), `CONTAINER`
  (default `cyberware`) + `DB_IN_CONTAINER` (default `/data/body/index.sqlite`), `SRC_DIRS`
  (colon-separated; default `~/.cyberware/fleet-ledgers`). Output: `backup.json`.

## Scope
Timestamped dirs are append-only (no prune — the corpus is small and the NAS's own
snapshots/versioning + cloud tier do retention). The perk never deletes, never writes outside
`NAS_DIR/<SCOPE>/` + the record_store. Scheduling is the operator's (launchd/cron firing the
governed claim); the perk stays single-shot and idempotent per stamp.

## How to use it
Copy `ledger.json` → `task-ledger.json`, set `NAS_DIR` + `record_store`, then
validate → compose → compile → oversight → executor (or claim it through govd).
