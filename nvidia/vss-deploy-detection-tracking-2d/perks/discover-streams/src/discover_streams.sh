#!/usr/bin/env bash
# discover_streams — localized from NVIDIA/skills vss-deploy-detection-tracking-2d (Apache-2.0). Structured-JSON audit line.
# Standalone op: deterministic, layout-agnostic enumeration of local video streams.
# Scans $RESOURCES for any dir containing .mp4/.mkv, lists them in stable sorted
# order, and cycles them to produce exactly STREAM_COUNT (id, url) pairs.
# Porter: translates USECASE + STREAM_COUNT env vars -> the impl's positional args,
# forces --format json, captures the JSON array under RECORD_STORE, and ALWAYS
# pre-creates its output (graceful degradation when no videos / no $RESOURCES).
set -uo pipefail
: "${USECASE:?}" "${STREAM_COUNT:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/streams.json"
# Always (re)create $OUT so the contract's output_exists holds even if the impl errors.
: > "$OUT"
bash "$HERE/discover_streams.impl.sh" "${USECASE}" "${STREAM_COUNT}" --format json \
    >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '[]\n' > "$OUT"
printf '{"tool":"discover_streams","status":"ok","usecase":"%s","stream_count":"%s","out":"%s"}\n' \
    "${USECASE}" "${STREAM_COUNT}" "$OUT"
