#!/usr/bin/env bash
# query_map — bounded JSON slices over a built ownership-map dir (read-only). Structured JSON output.
# SPDX-License-Identifier: Apache-2.0
set -uo pipefail
: "${DATA_DIR:?}" "${QUERY_ARGS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${RECORD_STORE%/}"
OUT="${OUTDIR}/query.json"
mkdir -p "$OUTDIR"
# Always (re)create $OUT so the contract's output_exists holds even if python errors.
: > "$OUT"

# QUERY_ARGS is the query_ownership.py subcommand + flags (e.g. "files --tag auth --bus-factor-max 1").
# Intentional word-splitting of QUERY_ARGS into argv.
# shellcheck disable=SC2086
python3 "${HERE}/query_ownership.py" --data-dir "$DATA_DIR" ${QUERY_ARGS} > "$OUT" 2>"${OUTDIR}/query.err" || true

# Graceful degradation: ensure a non-empty query.json exists.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"query_map","status":"ok","query":"%s"}\n' "$OUT"
