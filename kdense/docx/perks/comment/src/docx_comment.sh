#!/usr/bin/env bash
# docx_comment — add a comment (or threaded reply) into an unpacked .docx directory's comment parts. Structured JSON output.
set -uo pipefail
: "${UNPACKED_DIR:?UNPACKED_DIR (an unpacked .docx dir) required}" \
  "${COMMENT_ID:?COMMENT_ID (unique integer) required}" \
  "${COMMENT_TEXT:?COMMENT_TEXT (pre-escaped XML) required}" \
  "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/comment.log"
# Pre-create so the contract's output_exists holds even if the core fails or defusedxml is absent.
: > "$OUT"

# Optional flags.
EXTRA=()
[ -n "${COMMENT_AUTHOR:-}" ] && EXTRA+=(--author "$COMMENT_AUTHOR")
[ -n "${PARENT_ID:-}" ] && EXTRA+=(--parent "$PARENT_ID")

# comment.py reads templates relative to its own file; run it from src/ (HERE).
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/comment.py" "$UNPACKED_DIR" "$COMMENT_ID" "$COMMENT_TEXT" "${EXTRA[@]}" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"docx_comment","status":"ok","unpacked_dir":"%s","comment_id":"%s","log":"%s"}\n' "$UNPACKED_DIR" "$COMMENT_ID" "$OUT"
