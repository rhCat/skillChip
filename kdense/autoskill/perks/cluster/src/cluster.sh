#!/usr/bin/env bash
# cluster — segment a timeline JSON into sessions on idle gaps, then cluster sessions by
# app-signature, using the vendored cluster.py (segment_sessions + cluster_sessions). Pure
# stdlib; fully offline. Reads INPUT (timeline JSON array of events with ts/app/window_title);
# IDLE_GAP_MINUTES / MIN_SESSION_MINUTES / MIN_CLUSTER_SIZE optional (defaults 10/5/2).
# Writes clusters.json under RECORD_STORE. Structured-JSON audit line on stdout.
set -uo pipefail
: "${INPUT:?INPUT (path to timeline JSON) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/clusters.json"
: > "$OUT"

IDLE_GAP_MINUTES="${IDLE_GAP_MINUTES:-10}"
MIN_SESSION_MINUTES="${MIN_SESSION_MINUTES:-5}"
MIN_CLUSTER_SIZE="${MIN_CLUSTER_SIZE:-2}"

PYTHONPATH="$HERE" python3 - \
  "$INPUT" "$OUT" "$IDLE_GAP_MINUTES" "$MIN_SESSION_MINUTES" "$MIN_CLUSTER_SIZE" <<'PY' || true
import datetime as _dt
import json, sys
from cluster import cluster_sessions, segment_sessions

src, dst, idle_min, sess_min, min_clust = sys.argv[1:6]
idle_gap = int(float(idle_min)) * 60
min_session = int(float(sess_min)) * 60
min_cluster = int(float(min_clust))

try:
    events = json.load(open(src))
except Exception:
    events = []
if isinstance(events, dict):
    events = events.get("events", [])

# normalize ts: ISO strings -> epoch seconds (matches run.py behaviour)
clean = []
for e in events:
    if not isinstance(e, dict):
        continue
    ts = e.get("ts")
    if isinstance(ts, str):
        try:
            ts = int(_dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp())
        except Exception:
            continue
    if ts is None:
        continue
    clean.append({
        "ts": ts,
        "app": e.get("app", ""),
        "window_title": e.get("window_title", ""),
    })

sessions = segment_sessions(clean, idle_gap_seconds=idle_gap, min_session_seconds=min_session)
clusters = cluster_sessions(sessions, min_cluster_size=min_cluster)
with open(dst, "w") as fh:
    json.dump({"session_count": len(sessions), "clusters": clusters}, fh, indent=2)
PY

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"cluster","status":"ok","clusters":"%s"}\n' "$OUT"
