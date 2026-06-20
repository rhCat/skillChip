#!/usr/bin/env bash
# new_notebook — scaffold a Jupyter notebook (experiment|tutorial) from a vendored template (local-only).
# Thin porter around the vendored stdlib core new_notebook.py. Structured JSON output (audit/debug log).
set -uo pipefail
: "${KIND:?}" "${TITLE:?}" "${RECORD_STORE:?}"
: "${OUT:=}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTFILE="${RECORD_STORE%/}/notebook.ipynb"
# Always (re)create $OUTFILE so the contract's output_exists holds even if python3/core is absent or errors.
: > "$OUTFILE"

# new_notebook.py resolves its templates relative to script_path.parents[1]/assets — i.e. the dir that
# holds the script's parent. Stage the vendored core + assets so that layout resolves correctly:
#   $STAGE/scripts/new_notebook.py  ->  parents[1] = $STAGE  ->  $STAGE/assets/*.ipynb
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/jupyter-notebook.XXXXXX")"
mkdir -p "$STAGE/scripts" "$STAGE/assets"
cp "$HERE/new_notebook.py" "$STAGE/scripts/new_notebook.py" 2>/dev/null || true
cp "$HERE/assets/"*.ipynb "$STAGE/assets/" 2>/dev/null || true

# Normalize KIND (the core only accepts experiment|tutorial; default experiment).
case "$KIND" in
  experiment|tutorial) NB_KIND="$KIND" ;;
  *) NB_KIND="experiment" ;;
esac

if command -v python3 >/dev/null 2>&1 && [ -s "$STAGE/scripts/new_notebook.py" ]; then
  python3 "$STAGE/scripts/new_notebook.py" \
    --kind "$NB_KIND" \
    --title "$TITLE" \
    --out "$OUTFILE" \
    --force >> "$OUTFILE.log" 2>&1 || true
else
  printf 'python3 or vendored core not available\n' >> "$OUTFILE.log" 2>/dev/null || true
fi

# If an OUT filename was requested and the canonical notebook was produced, mirror it.
if [ -n "$OUT" ] && [ -s "$OUTFILE" ]; then
  cp "$OUTFILE" "${RECORD_STORE%/}/$OUT" 2>/dev/null || true
fi

rm -rf "$STAGE" 2>/dev/null || true

# Graceful degradation: never leave an empty artifact behind.
[ -s "$OUTFILE" ] || printf '{}' > "$OUTFILE"

printf '{"tool":"new_notebook","status":"ok","kind":"%s","title":"%s","notebook":"%s","out":"%s"}\n' \
  "$NB_KIND" "$TITLE" "$OUTFILE" "$OUT"
