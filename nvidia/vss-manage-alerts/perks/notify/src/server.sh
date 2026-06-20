#!/usr/bin/env bash
# server — localized from NVIDIA/skills vss-manage-alerts (Apache-2.0). Structured-JSON audit line.
# Launches the alert-notify FastAPI relay (server.py): receives VSS incident webhooks and fans them
# out to the configured backends (Slack / Dashboard). Always creates its output file and emits one
# JSON line on stdout, even when python3 / pip deps / the Slack token are unavailable (graceful degradation).
set -uo pipefail
: "${SLACK_BOT_TOKEN:?}" "${SLACK_CHANNEL_ID:?}" "${VST_ENDPOINT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/notify.json"
LOG="${RECORD_STORE%/}/webhook.log"
: > "$OUT"

# server.py reads its config from env vars (and a .env beside it). NOTIFY_BACKENDS defaults to
# 'dashboard'; flip to 'slack' so the provided Slack credentials are actually used by default.
export SLACK_BOT_TOKEN SLACK_CHANNEL_ID VST_ENDPOINT
export NOTIFY_BACKENDS="${NOTIFY_BACKENDS:-slack}"
export WEBHOOK_HOST="${WEBHOOK_HOST:-0.0.0.0}"
export WEBHOOK_PORT="${WEBHOOK_PORT:-9090}"
# Resolve vendored deps if they were installed into a local --target dir (see references/alert-notify.md Step 2).
export PYTHONPATH="${HERE}/.pip-packages:${PYTHONPATH:-}"

status="ok"
pid=""
if command -v python3 >/dev/null 2>&1; then
  # Long-lived server: launch detached so the governed step returns. webhook.log captures startup.
  nohup python3 "${HERE}/server.py" >>"$LOG" 2>&1 &
  pid="$!"
else
  printf 'python3 not found on PATH\n' >> "$LOG"
  status="python3_missing"
fi

printf '{"tool":"server","status":"%s","backends":"%s","port":"%s","pid":"%s","log":"%s","out":"%s"}\n' \
  "$status" "$NOTIFY_BACKENDS" "$WEBHOOK_PORT" "$pid" "$LOG" "$OUT" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
