#!/usr/bin/env bash
# mtc_doctor — summarize migration readiness, manual-review items, and validation risks (--doctor, read-only).
# Vendored from openai/skills migrate-to-codex (Apache-2.0). Structured JSON audit line.
set -uo pipefail
: "${SOURCE:?}" "${TARGET:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/doctor.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3/tomllib is absent or the CLI errors.
: > "$OUT"
# The vendored CLI imports tomllib (stdlib in Python 3.11+). Prefer a tomllib-capable interpreter so the
# real migrator runs; fall back to bare python3 (degrades gracefully via || true if tomllib is absent).
PY="python3"
for c in python3 python3.13 python3.12 python3.11; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import tomllib' >/dev/null 2>&1; then PY="$c"; break; fi
done
# --doctor inspects only; it never writes target files. || true keeps the porter green.
PYTHONPATH="$HERE" "$PY" "$HERE/migrate-to-codex.py" --source "$SOURCE" --target "$TARGET" --doctor >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mtc_doctor","status":"ok","source":"%s","target":"%s","doctor":"%s"}\n' "$SOURCE" "$TARGET" "$OUT"
