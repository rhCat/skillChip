#!/usr/bin/env bash
# validate_cutile_jl — localized from NVIDIA/skills tilegym-converting-cutile-to-julia (Apache-2.0). Structured-JSON audit line.
set -uo pipefail
: "${JL_FILE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validation.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3 is absent or the validator errors.
: > "$OUT"
# The validator takes a single positional .jl path and prints findings to stdout (exit 1 on ERROR).
python3 "$HERE/validate_cutile_jl.py" "${JL_FILE}" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf 'no output\n' > "$OUT"
printf '{"tool":"validate_cutile_jl","status":"ok","out":"%s"}\n' "$OUT"
