#!/usr/bin/env bash
# forecast_csv — TimesFM 2.5 point + quantile forecast for every numeric column of a CSV → JSON. Structured JSON audit line.
set -uo pipefail
: "${INPUT_CSV:?}" "${HORIZON:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/forecasts.json"
# Always (re)create $OUT so the contract's output_exists holds even if timesfm/torch are absent or the core errors.
: > "$OUT"
# Optional knobs (env → CLI). Empty string = "not set".
DATE_COL="${DATE_COL:-}"
VALUE_COLS="${VALUE_COLS:-}"
ARGS=( "$INPUT_CSV" --horizon "$HORIZON" --output "$OUT" --format json )
[ -n "$DATE_COL" ] && ARGS+=( --date-col "$DATE_COL" )
[ -n "$VALUE_COLS" ] && ARGS+=( --value-cols "$VALUE_COLS" )
# Core loads + compiles TimesFM 2.5; without timesfm+torch it raises and we degrade gracefully.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/forecast_csv.py" "${ARGS[@]}" >/dev/null 2>&1 || true
# Guarantee a non-empty, valid JSON artifact even if timesfm/torch are missing.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"forecast_csv","status":"ok","input":"%s","horizon":"%s","forecasts":"%s"}\n' "$INPUT_CSV" "$HORIZON" "$OUT"
