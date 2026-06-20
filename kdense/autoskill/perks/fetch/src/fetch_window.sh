#!/usr/bin/env bash
# fetch_window — paginate the local screenpipe /search API over [START, END] into a normalized
# timeline JSON, using the vendored fetch_window.py. Talks to the screenpipe daemon on loopback
# (default http://localhost:3030); SCREENPIPE_TOKEN bearer-auths if set. Degrades gracefully:
# if the daemon is unreachable the porter still writes a well-formed (empty) timeline so the
# contract holds offline. Writes timeline.json under RECORD_STORE. Structured-JSON audit line.
set -uo pipefail
: "${START:?START (ISO start time) is required}"
: "${END:?END (ISO end time) is required}"
: "${RECORD_STORE:?RECORD_STORE is required}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/timeline.json"
: > "$OUT"

SCREENPIPE_URL="${SCREENPIPE_URL:-http://localhost:3030}"
SCREENPIPE_TOKEN="${SCREENPIPE_TOKEN:-}"

PYTHONPATH="$HERE" python3 - \
  "$START" "$END" "$OUT" "$SCREENPIPE_URL" "$SCREENPIPE_TOKEN" <<'PY' || true
import json, sys, urllib.parse, urllib.request
from fetch_window import fetch_window

start, end, dst, base_url, token = sys.argv[1:6]
base_url = base_url.rstrip("/")


class _Resp:
    def __init__(self, payload):
        self._payload = payload

    def raise_for_status(self):
        return None

    def json(self):
        return self._payload


class _UrllibClient:
    """Minimal stdlib client matching the httpx surface fetch_window uses."""
    base_url = base_url

    def get(self, path, params=None, headers=None):
        url = base_url + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        req = urllib.request.Request(url, headers=headers or {})
        with urllib.request.urlopen(req, timeout=30) as fh:
            return _Resp(json.loads(fh.read().decode("utf-8")))


events = []
try:
    events = fetch_window(_UrllibClient(), start, end,
                          token=(token or None))
except Exception:
    events = []
with open(dst, "w") as fh:
    json.dump(events, fh, indent=2)
PY

[ -s "$OUT" ] || printf '[]' > "$OUT"
printf '{"tool":"fetch_window","status":"ok","timeline":"%s"}\n' "$OUT"
