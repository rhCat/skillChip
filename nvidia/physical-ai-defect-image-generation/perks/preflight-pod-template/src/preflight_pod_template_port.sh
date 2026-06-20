#!/usr/bin/env bash
# preflight_pod_template_port — localized from NVIDIA/skills physical-ai-defect-image-generation (Apache-2.0).
# Governed entry point: verify the OSMO POD_TEMPLATE meets DIG requirements — the
# nvoptix denoiser binary is hostPath-mounted at /usr/share/nvidia/nvoptix.bin and
# /dev/shm (dshm emptyDir) is >= the minimum GiB. Captures the core's verdict and
# exit code (0 ok / 1 malformed / 2 HTTP-403 / 3 HTTP-409 / 4 prereq-missing).
# Emits ONE line of structured JSON on stdout and ALWAYS creates its output file
# (graceful degradation, like terraform's tf_plan.sh) — offline / no-osmo records
# that and the porter still passes.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/pod_template_report.txt"
# Always (re)create $OUT so the contract's output_exists holds even when osmo/jq is absent.
: > "$OUT"

args=()
[ -n "${MIN_DSHM_GIB:-}" ] && args+=(--min-dshm-gib "$MIN_DSHM_GIB")

if ! command -v osmo >/dev/null 2>&1; then
  printf 'osmo CLI not on PATH — cannot show/verify POD_TEMPLATE offline (exit-code class: 4 prereq-missing).\n' >> "$OUT"
  printf '{"tool":"preflight_pod_template","status":"ok","verified":false,"verdict":4,"report":"%s"}\n' "$OUT"
  exit 0
fi

rc=0
bash "$HERE/preflight_pod_template.sh" "${args[@]}" >>"$OUT" 2>>"$OUT" || rc=$?
[ -s "$OUT" ] || printf 'preflight_pod_template produced no output (exit %s)\n' "$rc" > "$OUT"
verified=false; [ "$rc" -eq 0 ] && verified=true
printf '{"tool":"preflight_pod_template","status":"ok","verified":%s,"verdict":%s,"report":"%s"}\n' "$verified" "$rc" "$OUT"
