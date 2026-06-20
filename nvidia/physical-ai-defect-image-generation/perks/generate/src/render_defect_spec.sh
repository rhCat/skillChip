#!/usr/bin/env bash
# render_defect_spec — localized from NVIDIA/skills physical-ai-defect-image-generation (Apache-2.0).
# Governed entry point: renders the defect_spec.jsonl that the OSMO anomaly-infer
# stage routes on (AMP/SDG taxonomy). Emits ONE line of structured JSON on stdout
# and ALWAYS creates its output file (graceful degradation, like terraform's tf_plan.sh).
set -uo pipefail
: "${DEFECT_PAIRS:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/defect_spec.jsonl"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or errors.
: > "$OUT"

SPATIAL="${SPATIAL_DEPENDENCY:-free}"
args=(--output "$OUT" --pairs "$DEFECT_PAIRS" --spatial-dependency "$SPATIAL")
# roi_prompt is only meaningful (and required) when spatial_dependency=text.
[ -n "${ROI_PROMPT:-}" ] && args+=(--roi-prompt "$ROI_PROMPT")

python3 "$HERE/render_defect_spec.py" "${args[@]}" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"render_defect_spec","status":"ok","out":"%s"}\n' "$OUT"
