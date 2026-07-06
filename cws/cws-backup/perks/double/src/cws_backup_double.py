#!/usr/bin/env python3
"""cws_backup_double — double the node's governed history at the NAS: the ledger DB + the fleet
chain mirror, copied and READ-BACK VERIFIED, with a chained backup-ledger as the audit trail.

The durability model this serves (3-2-1): each node's tamper-evident chains are the TRUTH; copy 1
is the local disk (the live store + the fleetdash mirror of every node's value-free chains); copy 2
is the NAS share this perk writes; the NAS's own cloud backup is the off-site third. The perk is
the mac-main leg: snapshot the node's index.sqlite WAL-SAFELY (VACUUM INTO — never a raw cp of a
live WAL db), sweep the mirror dirs, land everything under NAS_DIR/<SCOPE>/<UTC-stamp>/, then
re-read every NAS byte and compare sha256 against the source (a copy that doesn't verify is not a
backup). Each verified run appends `{stamp, files, bytes, manifest_sha, db}` to a prev-hash-chained
backup-ledger on the share, so cws-ledgercheck/verify can re-verify the backup HISTORY itself.

MOUNT-DOWN GUARD (fail-closed): NAS_DIR must already exist and contain the operator-minted sentinel
`.cyberware-backup-target` — an unmounted mountpoint is an empty local dir, and writing there would
"succeed" while backing up nothing off-box. The sentinel proves the share is the one intended.

Reads from env: NAS_DIR (required — the mounted share dir holding the sentinel), SCOPE (subdir on
the share; default the local hostname), LEDGER_DB (path to a sqlite index to snapshot directly) OR
CONTAINER (default `cyberware` — snapshot /data/body/index.sqlite inside the container via docker;
LEDGER_DB wins when both are set), DB_IN_CONTAINER (default /data/body/index.sqlite), SRC_DIRS
(colon-separated dirs to double; default ~/.cyberware/fleet-ledgers), RECORD_STORE. Writes
RECORD_STORE/backup.json (+ the db snapshot under RECORD_STORE/staging/) + one JSON line.
Exit 0 iff every copied byte verified; any guard, snapshot, or verify failure refuses nonzero.
"""
from __future__ import annotations
import hashlib
import json
import os
import shutil
import socket
import subprocess
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

SENTINEL = ".cyberware-backup-target"


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def snapshot_db(staging):
    """WAL-safe snapshot of the node's ledger DB into the staging dir. LEDGER_DB (a direct path)
    wins; otherwise the docker mode snapshots inside CONTAINER and copies out. Returns
    (snapshot_path, source_label) or raises with the reason."""
    out = os.path.join(staging, "index.sqlite")
    direct = (os.environ.get("LEDGER_DB") or "").strip()
    if direct:
        if not os.path.isfile(direct):
            raise RuntimeError(f"LEDGER_DB not a file: {direct}")
        import sqlite3
        cx = sqlite3.connect(f"file:{os.path.abspath(direct)}?mode=ro", uri=True)
        cx.execute("VACUUM INTO ?", (out,))
        cx.close()
        return out, direct
    container = (os.environ.get("CONTAINER") or "cyberware").strip()
    db_in = (os.environ.get("DB_IN_CONTAINER") or "/data/body/index.sqlite").strip()
    tmp = "/tmp/cws-backup-snap.sqlite"
    code = ("import sqlite3; cx=sqlite3.connect('file:%s?mode=ro', uri=True); "
            "cx.execute(\"VACUUM INTO '%s'\"); cx.close()" % (db_in, tmp))
    for cmd in ([["docker", "exec", container, "rm", "-f", tmp]],
                [["docker", "exec", container, "python3", "-c", code]],
                [["docker", "cp", f"{container}:{tmp}", out]],
                [["docker", "exec", container, "rm", "-f", tmp]]):
        r = subprocess.run(cmd[0], capture_output=True, text=True)
        if r.returncode != 0 and "rm" not in cmd[0]:
            raise RuntimeError(f"db snapshot via docker failed: {' '.join(cmd[0][:3])}: {r.stderr.strip()[:200]}")
    return out, f"docker:{container}:{db_in}"


def collect(src_dirs, staging_db):
    """The copy set: [(source_path, dest_relpath)] — the db snapshot + every file under each source
    dir (keyed by the dir's basename so two sources can't collide silently... a collision refuses)."""
    plan = [(staging_db, os.path.join("db", "index.sqlite"))]
    seen_roots = set()
    for d in [s for s in src_dirs.split(":") if s.strip()]:
        d = os.path.abspath(os.path.expanduser(d.strip()))
        if not os.path.isdir(d):
            raise RuntimeError(f"SRC_DIRS entry not a dir: {d}")
        root_key = os.path.basename(d.rstrip("/"))
        if root_key in seen_roots:
            raise RuntimeError(f"SRC_DIRS basename collision on '{root_key}' — two sources would merge (refused)")
        seen_roots.add(root_key)
        for base, _dirs, files in os.walk(d):
            for fn in files:
                src = os.path.join(base, fn)
                rel = os.path.join("mirror", root_key, os.path.relpath(src, d))
                plan.append((src, rel))
    return plan


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "backup.json")
    os.makedirs(store, exist_ok=True)

    def refuse(reason):
        json.dump({"tool": "cws_backup_double", "verdict": "refused", "reason": reason}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_backup_double", "verdict": "refused", "reason": reason, "report": out}))
        return 1

    nas = os.path.abspath(os.path.expanduser((os.environ.get("NAS_DIR") or "").strip() or "/nonexistent"))
    scope = (os.environ.get("SCOPE") or socket.gethostname().split(".")[0]).strip()
    src_dirs = (os.environ.get("SRC_DIRS") or os.path.expanduser("~/.cyberware/fleet-ledgers")).strip()

    # mount-down guard: the share must be there AND be the intended target (sentinel), fail-closed
    if not os.path.isdir(nas):
        return refuse(f"NAS_DIR not a directory (share not mounted?): {nas}")
    if not os.path.isfile(os.path.join(nas, SENTINEL)):
        return refuse(f"NAS_DIR carries no {SENTINEL} sentinel — refusing (an unmounted mountpoint "
                      f"looks like an empty dir; mint the sentinel ON the share once, operator-side)")

    stamp = time.strftime("%Y-%m-%dT%H%M%SZ", time.gmtime())
    staging = os.path.join(store, "staging", stamp)
    os.makedirs(staging, exist_ok=True)
    try:
        snap, db_src = snapshot_db(staging)
        plan = collect(src_dirs, snap)
    except RuntimeError as e:
        return refuse(str(e))

    dest_root = os.path.join(nas, scope, stamp)
    manifest, bad, total = {}, [], 0
    for src, rel in plan:
        dst = os.path.join(dest_root, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        want = sha256_file(src)
        shutil.copyfile(src, dst)
        got = sha256_file(dst)                       # READ BACK from the share — the actual double check
        manifest[rel] = want
        total += os.path.getsize(src)
        if got != want:
            bad.append({"file": rel, "want": want, "got": got})
    manifest_path = os.path.join(dest_root, "MANIFEST.json")
    json.dump({"stamp": stamp, "scope": scope, "files": manifest}, open(manifest_path, "w"), indent=2)
    manifest_sha = sha256_file(manifest_path)

    if bad:
        json.dump({"tool": "cws_backup_double", "verdict": "verify_failed", "scope": scope, "stamp": stamp,
                   "bad": bad, "files": len(plan), "bytes": total}, open(out, "w"), indent=2)
        print(json.dumps({"tool": "cws_backup_double", "verdict": "verify_failed", "bad": len(bad),
                          "report": out}))
        return 1

    # the audit trail: a chained, origin-bound backup-ledger ON the share (re-verifiable history)
    lp = os.path.join(nas, scope, "backup-ledger.json")
    if os.path.isfile(lp):
        led = json.load(open(lp))
    else:
        led = {"chain": "backup-ledger", "schema": ledger.CURRENT_MAJOR,
               "entries": [ledger.genesis("backup-ledger",
                           hashlib.sha256(b"cws-backup/double:generation-zero").hexdigest())]}
    entries = led.setdefault("entries", [])
    record = {"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "stamp": stamp, "scope": scope,
              "files": len(plan), "bytes": total, "manifest_sha": manifest_sha, "db": db_src}
    entry = ledger.append(entries, record, led.get("schema", ledger.CURRENT_MAJOR))
    ledger.write_object_atomic(lp, led)

    json.dump({"tool": "cws_backup_double", "verdict": "ok", "scope": scope, "stamp": stamp,
               "files": len(plan), "bytes": total, "verified": True, "dest": dest_root,
               "manifest_sha": manifest_sha, "seq": entry["seq"], "backup_ledger": lp,
               "db": db_src}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_backup_double", "verdict": "ok", "files": len(plan), "bytes": total,
                      "seq": entry["seq"], "dest": dest_root, "report": out}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
