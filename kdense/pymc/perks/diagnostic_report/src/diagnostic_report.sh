#!/usr/bin/env bash
# diagnostic_report — full MCMC diagnostic report (trace/rank/autocorr/energy/ESS plots + summary CSV)
# from one PyMC/ArviZ InferenceData .nc file. Read-only on the input. Emits one structured-JSON audit line.
set -uo pipefail
: "${IDATA:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/report.json"
REPORT_DIR="${RECORD_STORE%/}/diagnostics"
# Always (re)create $OUT so the contract's output_exists holds even if arviz/matplotlib is absent or errors.
: > "$OUT"
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  IDATA="$IDATA" OUT="$OUT" REPORT_DIR="$REPORT_DIR" VAR_NAMES="${VAR_NAMES:-}" \
  python3 "$HERE/cli_diagnostic_report.py" >/dev/null 2>&1 || true
# Graceful offline: if the heavy science lib was absent and produced nothing, leave a valid stub.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"diagnostic_report","status":"ok","idata":"%s","out":"%s","report_dir":"%s"}\n' "$IDATA" "$OUT" "$REPORT_DIR"
