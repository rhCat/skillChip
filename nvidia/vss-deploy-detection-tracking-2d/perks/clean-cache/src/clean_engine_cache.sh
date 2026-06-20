#!/usr/bin/env bash
# clean_engine_cache — localized from NVIDIA/skills vss-deploy-detection-tracking-2d (Apache-2.0). Structured-JSON audit line.
# Standalone op: relocate non-engine files (anything not *.engine / *.plan) OUT of
# the TRT engine cache dir into <cache>/.quarantine/. Idempotent; never deletes.
# Porter: translates CACHE_DIR env var -> the impl's --cache-dir arg (DRY_RUN=1
# selects --dry-run), captures the report under RECORD_STORE, and ALWAYS
# pre-creates its output (graceful degradation when the cache dir is absent).
set -uo pipefail
: "${CACHE_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/clean-cache.txt"
ARGS=(--cache-dir "${CACHE_DIR}")
[ "${DRY_RUN:-0}" = "1" ] && ARGS+=(--dry-run)
# Always (re)create $OUT so the contract's output_exists holds even if the impl errors.
: > "$OUT"
bash "$HERE/clean_engine_cache.impl.sh" ${ARGS[@]+"${ARGS[@]}"} >"$OUT" 2>>"$OUT" || true
[ -s "$OUT" ] || printf 'CLEAN_CACHE: no output for CACHE_DIR=%s\n' "${CACHE_DIR}" > "$OUT"
printf '{"tool":"clean_engine_cache","status":"ok","cache_dir":"%s","dry_run":"%s","out":"%s"}\n' \
    "${CACHE_DIR}" "${DRY_RUN:-0}" "$OUT"
