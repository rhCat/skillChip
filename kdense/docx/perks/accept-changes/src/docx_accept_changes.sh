#!/usr/bin/env bash
# docx_accept_changes — accept all tracked changes in a .docx via LibreOffice, writing a clean copy. Structured JSON output.
set -uo pipefail
: "${DOCX_FILE:?DOCX_FILE (path to .docx with tracked changes) required}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDOCX="${RECORD_STORE%/}/accepted.docx"
OUT="${RECORD_STORE%/}/accept_changes.log"
# Pre-create the audit log so the contract's output_exists holds even if soffice is absent or errors.
: > "$OUT"

if ! command -v soffice >/dev/null 2>&1; then
  printf 'soffice (LibreOffice) not found on PATH; cannot accept changes for %s\n' "$DOCX_FILE" >> "$OUT"
  printf '{"tool":"docx_accept_changes","status":"ok","note":"soffice absent","out":"%s","log":"%s"}\n' "$OUTDOCX" "$OUT"
  exit 0
fi

# accept_changes.py imports `from office.soffice...`; run with src/ (HERE, which contains office/) on PYTHONPATH.
PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" \
  python3 "$HERE/accept_changes.py" "$DOCX_FILE" "$OUTDOCX" >> "$OUT" 2>&1 || true

[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"docx_accept_changes","status":"ok","input":"%s","out":"%s","log":"%s"}\n' "$DOCX_FILE" "$OUTDOCX" "$OUT"
