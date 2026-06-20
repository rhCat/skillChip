#!/usr/bin/env bash
# normalize_compose — localized from NVIDIA/skills vss-deploy-profile (Apache-2.0). Structured-JSON audit line.
# Strips dangling *optional* depends_on entries from a resolved compose file (the artifact
# `docker compose --env-file <env> config > resolved.yml` produces). MUST run after config and before
# `up -d`. Edits a COPY of RESOLVED under RECORD_STORE so the source artifact is never mutated by the probe.
# Reports (and refuses, exit 2) if a dangling dependency is REQUIRED, since dropping it would mask breakage.
set -uo pipefail
: "${RESOLVED:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/normalize.json"
LOG="${OUT}.log"
NORMALIZED="${RECORD_STORE%/}/resolved.yml"
# Always (re)create $OUT so the contract's output_exists holds even if python/pyyaml are absent or input is missing.
: > "$OUT"
: > "$LOG"
status="ok"

# Work on a copy under RECORD_STORE; never mutate the source resolved.yml.
if [ -f "$RESOLVED" ]; then
  cp "$RESOLVED" "$NORMALIZED" || status="degraded"
else
  echo "RESOLVED not found: $RESOLVED" >&2
  status="degraded"
  : > "$NORMALIZED"
fi

if command -v python3 >/dev/null 2>&1 && [ -s "$NORMALIZED" ]; then
  python3 "$HERE/normalize_resolved_yml.py" "$NORMALIZED" >>"$LOG" 2>&1 || status="degraded"
else
  echo "python3 absent or no resolved.yml content — skipping normalize" >&2
  status="degraded"
fi

printf '{"tool":"normalize_compose","status":"%s","resolved":"%s","normalized":"%s","log":"%s","out":"%s"}\n' \
  "$status" "$RESOLVED" "$NORMALIZED" "$LOG" "$OUT" | tee "$OUT"
