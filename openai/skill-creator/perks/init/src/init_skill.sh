#!/usr/bin/env bash
# init_skill — porter: scaffolds a new skill dir from template via the vendored init_skill.py core.
# The logic lives in init_skill.py (standalone — inspect / lint / test it directly); it imports the
# sibling generate_openai_yaml.py, so PYTHONPATH points at this dir. Structured JSON output.
set -uo pipefail
: "${SKILL_NAME:?}" "${OUTPUT_PATH:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/init.out"
# Always (re)create $OUT so the contract's output_exists holds even if python3/pyyaml is absent or errors.
: > "$OUT"
# env -> arg translation: SKILL_NAME positional, OUTPUT_PATH -> --path, optional RESOURCES -> --resources.
ARGS=("$SKILL_NAME" "--path" "$OUTPUT_PATH")
[ -n "${RESOURCES:-}" ] && ARGS+=("--resources" "$RESOURCES")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/init_skill.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"init_skill","status":"ok","skill":"%s","report":"%s"}\n' "$SKILL_NAME" "$OUT"
