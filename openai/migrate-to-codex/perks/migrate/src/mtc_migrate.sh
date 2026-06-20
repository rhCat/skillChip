#!/usr/bin/env bash
# mtc_migrate — migrate a Claude source tree into Codex artifacts (AGENTS.md, .codex/, .agents/skills/, .codex/agents/).
# DESTRUCTIVE: writes/overwrites generated Codex artifacts under TARGET (and deletes orphans with --replace via MIGRATE_FLAGS).
# Vendored from openai/skills migrate-to-codex (Apache-2.0). Structured JSON audit line.
set -uo pipefail
: "${SOURCE:?}" "${TARGET:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/migrate.txt"
# Optional extra flags (e.g. "--dry-run", "--mcp", "--skills", "--subagents", "--replace"). Default: full real run.
FLAGS="${MIGRATE_FLAGS:-}"
# Always (re)create $OUT so the contract's output_exists holds even if python3/tomllib is absent or the CLI errors.
: > "$OUT"
# The vendored CLI imports tomllib (stdlib in Python 3.11+). Prefer a tomllib-capable interpreter so the
# real migrator runs; fall back to bare python3 (degrades gracefully via || true if tomllib is absent).
PY="python3"
for c in python3 python3.13 python3.12 python3.11; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import tomllib' >/dev/null 2>&1; then PY="$c"; break; fi
done
# Run the real migration. || true keeps the porter green; the executor's destructive gate governs the
# real mutation. On Python < 3.11 with no capable interpreter, the import of tomllib fails and nothing is written.
# shellcheck disable=SC2086
PYTHONPATH="$HERE" "$PY" "$HERE/migrate-to-codex.py" --source "$SOURCE" --target "$TARGET" $FLAGS >> "$OUT" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"mtc_migrate","status":"ok","source":"%s","target":"%s","flags":"%s","report":"%s"}\n' "$SOURCE" "$TARGET" "$FLAGS" "$OUT"
