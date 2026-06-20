#!/usr/bin/env bash
# community_maintainers — monthly/quarterly maintainers for a file's community (read-only). Structured JSON output.
# SPDX-License-Identifier: Apache-2.0
set -uo pipefail
: "${DATA_DIR:?}" "${CM_ARGS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${RECORD_STORE%/}"
OUT="${OUTDIR}/community_maintainers.csv"
mkdir -p "$OUTDIR"
# Always (re)create $OUT so the contract's output_exists holds even if python errors.
: > "$OUT"

# CM_ARGS holds the community_maintainers.py flags (e.g. "--file network/card.c --since 2025-01-01 --top 5").
# Intentional word-splitting of CM_ARGS into argv.
# shellcheck disable=SC2086
python3 "${HERE}/community_maintainers.py" --data-dir "$DATA_DIR" ${CM_ARGS} > "$OUT" 2>"${OUTDIR}/community_maintainers.err" || true

# Graceful degradation: ensure a non-empty CSV exists (header only if the core produced nothing).
[ -s "$OUT" ] || printf 'period,rank,name,email,primary_tz_offset,community_touches,touch_share\n' > "$OUT"
printf '{"tool":"community_maintainers","status":"ok","report":"%s"}\n' "$OUT"
