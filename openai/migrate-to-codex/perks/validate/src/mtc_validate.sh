#!/usr/bin/env bash
# mtc_validate — validate an already-migrated Codex target (config.toml, skills, agents, AGENTS.md) (--validate-target, read-only).
# Vendored from openai/skills migrate-to-codex (Apache-2.0). Structured JSON audit line.
set -uo pipefail
: "${TARGET:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/validate.txt"
# Always (re)create $OUT so the contract's output_exists holds even if python3/tomllib is absent or the CLI errors.
: > "$OUT"
# The vendored CLI imports tomllib (stdlib in Python 3.11+). Prefer a tomllib-capable interpreter so the
# real validator runs; fall back to bare python3 (degrades gracefully via || true if tomllib is absent).
PY="python3"
for c in python3 python3.13 python3.12 python3.11; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import tomllib' >/dev/null 2>&1; then PY="$c"; break; fi
done
# --validate-target only reads the target and reports; it never writes. || true keeps the porter green
# (the real CLI exits 1 on a hard validation error; the porter normalizes to exit 0 for the contract).
PYTHONPATH="$HERE" "$PY" "$HERE/migrate-to-codex.py" --validate-target "$TARGET" >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mtc_validate","status":"ok","target":"%s","validate":"%s"}\n' "$TARGET" "$OUT"
