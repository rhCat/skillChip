#!/usr/bin/env bash
# recipe_tool — localized from NVIDIA/skills dynamo-recipe-runner (Apache-2.0). Structured-JSON audit line.
# Read-only preflight: runs `recipe_tool.py validate <target>` and captures its JSON report.
set -uo pipefail
: "${RECIPE_TARGET:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validate.json"
# Always (re)create $OUT so the contract's output_exists holds even if python/repo is absent or errors.
: > "$OUT"
# recipe_tool.py resolves the Dynamo repo root from CWD (a dir holding both recipes/ and .git);
# its validate subcommand prints the JSON report to stdout, which we capture into $OUT.
python3 "$HERE/recipe_tool.py" validate "${RECIPE_TARGET}" >"$OUT" 2>"$OUT.log" || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"recipe_tool","status":"ok","out":"%s"}\n' "$OUT"
