#!/usr/bin/env bash
# hsb_phase_runner — localized from NVIDIA/skills hsb-setup (Apache-2.0). Structured-JSON audit line.
# Porter: exports the skill's env vars and drives the vendored phase runner
# (hsb_phase_runner.impl.sh), which executes a phase command with timestamped
# logging. The mandatory Phase 0 token-budget preflight is the governed entry
# step here — no remote SSH / host config / container build happens until the
# operator drives subsequent phases. Always creates $OUT for graceful degradation.
set -uo pipefail
: "${SSH_TARGET:?}" "${REMOTE_ROOT:?}" "${RECORD_STORE:?}"
HSB_PLATFORM="${HSB_PLATFORM:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/hsb_setup.json"
# Always (re)create $OUT so the contract's output_exists holds even if the runner errors.
: > "$OUT"

export SSH_TARGET REMOTE_ROOT HSB_PLATFORM
export LOG_DIR="${RECORD_STORE%/}/hsb-skill-logs"

# Phase 0 — token-budget preflight (mandatory, non-destructive first step).
# Driven through the vendored runner so each phase is captured to a timestamped log.
bash "$HERE/hsb_phase_runner.impl.sh" phase0-preflight \
  printf 'HSB preflight: SSH_TARGET=%s REMOTE_ROOT=%s HSB_PLATFORM=%s\n' \
  "$SSH_TARGET" "$REMOTE_ROOT" "${HSB_PLATFORM:-<auto-detect>}" >>"$OUT.log" 2>&1 || true

# Emit a structured audit record as the tool's output file.
printf '{"tool":"hsb_phase_runner","phase":"phase0-preflight","ssh_target":"%s","remote_root":"%s","platform":"%s","log_dir":"%s"}\n' \
  "$SSH_TARGET" "$REMOTE_ROOT" "${HSB_PLATFORM:-}" "$LOG_DIR" > "$OUT"
[ -s "$OUT" ] || printf '{}' > "$OUT"

printf '{"tool":"hsb_phase_runner","status":"ok","out":"%s"}\n' "$OUT"
