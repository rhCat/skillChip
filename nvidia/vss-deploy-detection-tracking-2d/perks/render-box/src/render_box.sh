#!/usr/bin/env bash
# render_box — localized from NVIDIA/skills vss-deploy-detection-tracking-2d (Apache-2.0). Structured-JSON audit line.
# Standalone op: render a perfectly-aligned fixed-width light-box receipt. Reads
# body content (one row per line) from a file and emits the boxed step receipt.
# Porter: translates TITLE + BODY_FILE env vars -> the impl's --title arg + stdin,
# captures the rendered box under RECORD_STORE, and ALWAYS pre-creates its output
# (graceful degradation when BODY_FILE is missing / impl errors).
set -uo pipefail
: "${TITLE:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/box.txt"
WIDTH="${WIDTH:-128}"
# Always (re)create $OUT so the contract's output_exists holds even if the impl errors.
: > "$OUT"
# Body comes from $BODY_FILE when set+readable, else from an empty stream.
if [ -n "${BODY_FILE:-}" ] && [ -r "${BODY_FILE}" ]; then
    bash "$HERE/render_box.impl.sh" --title "${TITLE}" --width "${WIDTH}" \
        <"${BODY_FILE}" >"$OUT" 2>"$OUT.log" || true
else
    : | bash "$HERE/render_box.impl.sh" --title "${TITLE}" --width "${WIDTH}" \
        >"$OUT" 2>"$OUT.log" || true
fi
[ -s "$OUT" ] || printf '# render_box produced no output for TITLE=%s (see %s.log)\n' "${TITLE}" "$OUT" > "$OUT"
printf '{"tool":"render_box","status":"ok","title":"%s","width":"%s","out":"%s"}\n' \
    "${TITLE}" "${WIDTH}" "$OUT"
