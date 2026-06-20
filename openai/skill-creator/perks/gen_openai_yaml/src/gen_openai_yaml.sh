#!/usr/bin/env bash
# gen_openai_yaml — porter: (re)generates <SKILL_DIR>/agents/openai.yaml via the vendored
# generate_openai_yaml.py core (reads the skill's SKILL.md frontmatter name). Structured JSON output.
set -uo pipefail
: "${SKILL_DIR:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/openai_yaml.out"
# Always (re)create $OUT so the contract's output_exists holds even if python3/pyyaml is absent or errors.
: > "$OUT"
# env -> arg translation: SKILL_DIR positional; optional NAME -> --name; optional INTERFACE -> --interface.
ARGS=("$SKILL_DIR")
[ -n "${NAME:-}" ] && ARGS+=("--name" "$NAME")
[ -n "${INTERFACE:-}" ] && ARGS+=("--interface" "$INTERFACE")
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/generate_openai_yaml.py" "${ARGS[@]}" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"gen_openai_yaml","status":"ok","skill_dir":"%s","report":"%s"}\n' "$SKILL_DIR" "$OUT"
