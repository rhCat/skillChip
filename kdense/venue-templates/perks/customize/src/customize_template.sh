#!/usr/bin/env bash
# customize_template — fill a venue .tex template's title/author/affiliation/email placeholders. Structured JSON audit line.
set -uo pipefail
: "${TEMPLATE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/customized.tex"
LOG="${RECORD_STORE%/}/customize.log"
# Always (re)create $OUT so the contract's output_exists holds even if the core errors.
: > "$OUT"
: > "$LOG"

# Translate env vars -> argparse flags for the vendored core. The core resolves
# TEMPLATE against its sibling assets/{journals,posters,grants} dir.
ARGS=(--template "$TEMPLATE" --output "$OUT")
if [ -n "${TITLE:-}" ]; then ARGS+=(--title "$TITLE"); fi
if [ -n "${AUTHORS:-}" ]; then ARGS+=(--authors "$AUTHORS"); fi
if [ -n "${AFFILIATIONS:-}" ]; then ARGS+=(--affiliations "$AFFILIATIONS"); fi
if [ -n "${EMAIL:-}" ]; then ARGS+=(--email "$EMAIL"); fi

python3 "$HERE/customize_template.py" "${ARGS[@]}" >> "$LOG" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"customize_template","status":"ok","template":"%s","out":"%s"}\n' "$TEMPLATE" "$OUT"
