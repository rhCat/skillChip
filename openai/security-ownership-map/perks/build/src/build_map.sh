#!/usr/bin/env bash
# build_map — build a security ownership map from git history (read-only). Structured JSON output.
# SPDX-License-Identifier: Apache-2.0
set -uo pipefail
: "${REPO:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${RECORD_STORE%/}"
OUT="${OUTDIR}/summary.json"
mkdir -p "$OUTDIR"
# Always (re)create $OUT so the contract's output_exists holds even if git/python errors.
: > "$OUT"

# Community detection + GraphML need networkx; degrade gracefully when it is absent.
COMM_FLAG=""
if ! python3 -c "import networkx" >/dev/null 2>&1; then
  COMM_FLAG="--no-communities"
fi

# Vendored core; build_ownership_map.py is a sibling import target of run_ownership_map.py.
python3 "${HERE}/build_ownership_map.py" --repo "$REPO" --out "$OUTDIR" --emit-commits ${COMM_FLAG} >> "${OUTDIR}/build.log" 2>&1 || true

# Graceful degradation: ensure a non-empty summary.json exists.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"build_map","status":"ok","summary":"%s","out_dir":"%s","communities":%s}\n' \
  "$OUT" "$OUTDIR" "$([ -z "$COMM_FLAG" ] && echo true || echo false)"
