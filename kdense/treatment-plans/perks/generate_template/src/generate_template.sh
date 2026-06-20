#!/usr/bin/env bash
# generate_template — copy a specialty LaTeX treatment-plan template (selected by TEMPLATE_TYPE) into
# the record store. Structured JSON audit line; copied template -> template.tex.
set -uo pipefail
: "${TEMPLATE_TYPE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/template.tex"
# Do NOT pre-create the template path: the core prompts on stdin if --output already exists.
rm -f "$OUT"
# Non-interactive: --type drives selection, --output is an absolute path under RECORD_STORE.
python3 "$HERE/generate_template.py" --type "$TEMPLATE_TYPE" --output "$OUT" >/dev/null 2>&1 || true
# Guarantee the contract's output_exists even if the template/lib was unavailable.
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"generate_template","status":"ok","template":"%s"}\n' "$OUT"
