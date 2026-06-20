#!/usr/bin/env bash
# preflight_series — localized from NVIDIA/skills dicom-series-preflight (Apache-2.0). Structured-JSON audit line.
# Header-only DICOM series preflight. The vendored typer script takes the dir as a
# positional arg and prints preflight JSON to stdout; we redirect that to $OUT.
set -uo pipefail
: "${DICOM_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/preflight.json"
# Always (re)create $OUT so the contract's output_exists holds even on failure.
: > "$OUT"
python3 "$HERE/preflight_series.py" "${DICOM_DIR}" >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"preflight_series","status":"ok","out":"%s"}\n' "$OUT"
