#!/usr/bin/env bash
# check_permissions — preflight macOS Screen Recording permission before window/app capture.
# Thin governed porter around the vendored ensure_macos_permissions.sh core. Records status only;
# does not mutate user data. Structured JSON audit line on stdout. Graceful degradation: off macOS,
# in a sandbox, or with swift absent it records the unavailable/blocked status instead of failing.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/permissions.json"
# Always (re)create $OUT so the contract's output_exists holds even when the check cannot run.
: > "$OUT"

os="$(uname 2>/dev/null || printf unknown)"
status="unknown"
detail=""

if [ "$os" != "Darwin" ]; then
  status="not_applicable"
  detail="Screen Recording permission is macOS-only; nothing to check on $os"
elif ! command -v swift >/dev/null 2>&1; then
  status="unavailable"
  detail="swift not found; install Xcode command line tools to check Screen Recording permission"
elif [ -n "${CODEX_SANDBOX:-}" ]; then
  status="blocked"
  detail="screen capture checks are blocked in the sandbox; rerun with escalated permissions"
else
  # Live preflight: the helper checks (and may request) Screen Recording in one place.
  out="$(bash "$HERE/ensure_macos_permissions.sh" 2>&1 || true)"
  detail="$(printf '%s' "$out" | tr '\n' ' ' | sed 's/"/'"'"'/g')"
  if printf '%s' "$out" | grep -qi "permission already granted\|permission granted"; then
    status="granted"
  else
    status="not_granted"
  fi
fi

# Emit a structured status record (single-object JSON) to the artifact.
printf '{"tool":"check_permissions","os":"%s","screen_recording":"%s","detail":"%s"}\n' \
  "$os" "$status" "$detail" > "$OUT"
# Graceful degradation: never leave an empty artifact.
[ -s "$OUT" ] || printf '{}' > "$OUT"

# Emit the audit line.
printf '{"tool":"check_permissions","status":"ok","os":"%s","screen_recording":"%s","report":"%s"}\n' \
  "$os" "$status" "$OUT"
