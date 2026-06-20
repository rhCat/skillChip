#!/usr/bin/env bash
# render_notification — localized from NVIDIA/skills vss-manage-alerts (Apache-2.0). Structured-JSON audit line.
# Renders a VSS incident payload into the Slack Block Kit blocks and OpenClaw Dashboard markdown that the
# live alert-notify relay would post — fully offline (no Slack token, no running server, no network). Exercises
# the vendored pure formatters (build_slack_blocks / build_dashboard_message / build_test_incident). Always
# creates its output file and emits one JSON line on stdout, even when python3 is unavailable (graceful degradation).
set -uo pipefail
: "${RECORD_STORE:?}"
INCIDENT="${INCIDENT:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/render.json"
RENDERED="${RECORD_STORE%/}/rendered.json"
: > "$OUT"
: > "$RENDERED"

export PYTHONPATH="${HERE}:${PYTHONPATH:-}"

status="ok"
if command -v python3 >/dev/null 2>&1; then
  # Env->arg translation: out-dir = RECORD_STORE, optional incident file second.
  python3 "${HERE}/render_notification.py" "${RECORD_STORE%/}" "${INCIDENT}" >/dev/null 2>>"${RECORD_STORE%/}/render.log" || status="render_failed"
else
  status="python3_missing"
fi
[ -s "$RENDERED" ] || status="${status/ok/render_empty}"

printf '{"tool":"render_notification","status":"%s","incident":"%s","rendered":"%s","out":"%s"}\n' \
  "$status" "${INCIDENT:-<test-incident>}" "$RENDERED" "$OUT" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"
cat "$OUT"
