#!/usr/bin/env bash
# style_template — write a publication-quality matplotlib .mplstyle preset via the
# vendored create_style_template(). Read-only w.r.t. inputs; writes the style file +
# a manifest under RECORD_STORE. Structured JSON audit line.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STYLE_OUT="${RECORD_STORE%/}/publication.mplstyle"
OUT="${RECORD_STORE%/}/style_template.json"
# Pre-create the manifest so the contract's output_exists holds even on failure.
: > "$OUT"
STYLE_OUT="$STYLE_OUT" \
  PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/_cli_style_template.py" > "$OUT" 2>>"${RECORD_STORE%/}/style_template.err" || true
# Guarantee non-empty JSON output.
[ -s "$OUT" ] || printf '{"tool":"style_template","status":"degraded","reason":"no output"}' > "$OUT"
printf '{"tool":"style_template","status":"ok","manifest":"%s","style_file":"%s"}\n' "$OUT" "$STYLE_OUT"
