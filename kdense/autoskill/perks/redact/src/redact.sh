#!/usr/bin/env bash
# redact — scrub emails, API keys, bearer tokens, JWTs, phones, SSNs from a timeline JSON
# (text + window_title fields) using the vendored redact.py. Pure stdlib; fully offline.
# Reads INPUT (a timeline JSON array of {ts,app,window_title,text,content_type}),
# writes redacted.json under RECORD_STORE. Structured-JSON audit line on stdout.
set -uo pipefail
: "${INPUT:?INPUT (path to timeline JSON) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/redacted.json"
: > "$OUT"

PYTHONPATH="$HERE" python3 - "$INPUT" "$OUT" <<'PY' || true
import json, sys
from redact import redact

src, dst = sys.argv[1], sys.argv[2]
try:
    events = json.load(open(src))
except Exception:
    events = []
if isinstance(events, dict):
    events = events.get("events", [])
for e in events:
    if not isinstance(e, dict):
        continue
    e["text"] = redact(e.get("text", "") or "")
    e["window_title"] = redact(e.get("window_title", "") or "")
with open(dst, "w") as fh:
    json.dump(events, fh, indent=2)
PY

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"redact","status":"ok","redacted":"%s"}\n' "$OUT"
