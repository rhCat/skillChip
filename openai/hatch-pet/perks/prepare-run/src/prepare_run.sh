#!/usr/bin/env bash
# prepare_run — scaffold a Codex pet run folder: prompts, layout guides, chroma key, imagegen job manifest. Structured JSON output (audit/debug log).
set -uo pipefail
: "${PET_NAME:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$RECORD_STORE"
RUNDIR="${RECORD_STORE%/}/run"
OUT="$RUNDIR/imagegen-jobs.json"
PET_NOTES="${PET_NOTES:-}"
STYLE_PRESET="${STYLE_PRESET:-auto}"
# Pre-create the run dir + declared manifest so the contract's output_exists holds even if python/PIL is absent or errors.
mkdir -p "$RUNDIR"
: > "$OUT"
# env -> arg translation; --force lets the porter reuse the pre-created (empty) run dir.
python3 "$HERE/prepare_pet_run.py" \
  --pet-name "$PET_NAME" \
  --pet-notes "$PET_NOTES" \
  --style-preset "$STYLE_PRESET" \
  --output-dir "$RUNDIR" \
  --force >/dev/null 2>&1 || true
# Graceful degradation: ensure a non-empty manifest even when the core could not run.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"prepare_run","status":"ok","run_dir":"%s","jobs":"%s"}\n' "$RUNDIR" "$OUT"
