#!/usr/bin/env bash
# preflight_credentials — localized from NVIDIA/skills physical-ai-video-data-augmentation (Apache-2.0).
# Thin porter: translates env vars -> preflight_credentials.impl.sh CLI args, writes under
# RECORD_STORE, and ALWAYS creates its output file (graceful degradation). Emits ONE structured-JSON
# audit line on stdout.
set -uo pipefail
: "${WORKFLOW:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/preflight.txt"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors or deps are absent.
: > "$OUT"

ARGS=(--workflow "${WORKFLOW}")
# Optional knobs surfaced as env flags (default off): NO_PROBE=1 skips outbound probes; REFRESH=1 forces
# OSMO credential overwrite. Mirrors preflight_credentials.impl.sh --no-probe / --refresh.
[ "${NO_PROBE:-0}" = "1" ] && ARGS+=(--no-probe)
[ "${REFRESH:-0}" = "1" ] && ARGS+=(--refresh)

status="ok"
bash "$HERE/preflight_credentials.impl.sh" "${ARGS[@]}" >>"$OUT" 2>&1 || status="degraded"
[ -s "$OUT" ] || printf 'preflight produced no output\n' > "$OUT"
printf '{"tool":"preflight_credentials","status":"%s","out":"%s"}\n' "$status" "$OUT"
