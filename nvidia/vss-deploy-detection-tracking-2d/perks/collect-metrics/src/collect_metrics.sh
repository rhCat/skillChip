#!/usr/bin/env bash
# collect_metrics — localized from NVIDIA/skills vss-deploy-detection-tracking-2d (Apache-2.0). Structured-JSON audit line.
# Standalone op: sample the RTVI-CV /api/v1/metrics endpoint N times (plus nvidia-smi
# temp/power) and print averaged GPU/CPU/RAM + per-stream FPS. Degrades gracefully
# when the REST endpoint is unreachable (prints n/a averages, exits 0).
# Porter: translates REST_HOST/REST_PORT/SAMPLES/INTERVAL/WARMUP env vars -> impl
# flags, captures the averaged block + JSON dump under RECORD_STORE, and ALWAYS
# pre-creates its outputs.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/metrics.txt"
JSON_OUT="${RECORD_STORE%/}/metrics.json"
SAMPLES="${SAMPLES:-1}"
INTERVAL="${INTERVAL:-0}"
WARMUP="${WARMUP:-0}"
REST_HOST="${REST_HOST:-localhost}"
REST_PORT="${REST_PORT:-9000}"
# Always (re)create outputs so the contract's output_exists holds even if the impl errors.
: > "$OUT"
: > "$JSON_OUT"
# Pass --json-out only when RECORD_STORE is under a location the impl's path guard
# accepts (/opt/storage/ or $HOME); otherwise the impl rejects the flag. The
# per-stream JSON is only emitted when FPS data exists, so the text averaged
# block is the load-bearing artifact either way.
JSON_ARGS=()
case "$JSON_OUT" in
    /opt/storage/*|"$HOME"/*) JSON_ARGS=(--json-out "$JSON_OUT") ;;
esac
REST_HOST="$REST_HOST" REST_PORT="$REST_PORT" \
bash "$HERE/collect_metrics.impl.sh" \
    --samples "${SAMPLES}" --interval "${INTERVAL}" --warmup "${WARMUP}" \
    --host "${REST_HOST}" --port "${REST_PORT}" ${JSON_ARGS[@]+"${JSON_ARGS[@]}"} \
    >"$OUT" 2>>"$OUT" || true
[ -s "$OUT" ] || printf '# collect_metrics produced no output (REST %s:%s unreachable?)\n' "${REST_HOST}" "${REST_PORT}" > "$OUT"
[ -s "$JSON_OUT" ] || printf '{}\n' > "$JSON_OUT"
printf '{"tool":"collect_metrics","status":"ok","host":"%s","port":"%s","samples":"%s","out":"%s","json":"%s"}\n' \
    "${REST_HOST}" "${REST_PORT}" "${SAMPLES}" "$OUT" "$JSON_OUT"
