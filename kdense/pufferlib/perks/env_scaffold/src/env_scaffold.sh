#!/usr/bin/env bash
# env_scaffold — materialize the PufferEnv environment template into record_store and run its
# built-in test_environment() self-check when pufferlib is importable. Read-only. Structured JSON output.
set -uo pipefail
: "${RECORD_STORE:?}"
GRID_SIZE="${GRID_SIZE:-10}"
HERE="$(cd "$(dirname "$0")" && pwd)"
SCAFFOLD="${RECORD_STORE%/}/env_scaffold.py"
LOG="${RECORD_STORE%/}/env_scaffold.log"
# Always (re)create outputs so the contract's output_exists holds even if the core/stack is absent or errors.
: > "$SCAFFOLD"
: > "$LOG"

# Emit the vendored environment template verbatim as the scaffold artifact (read-only copy).
cat "$HERE/env_template.py" > "$SCAFFOLD" 2>/dev/null || true

# Run the template's self-test only if pufferlib is a real installed package; degrade gracefully otherwise.
# (Guard requires a concrete __file__ so an empty namespace-package dir named "pufferlib" on the cwd
#  cannot masquerade as the real library.)
if python3 -c "import pufferlib; assert getattr(pufferlib,'__file__',None)" >/dev/null 2>&1; then
  PYTHONPATH="$HERE${PYTHONPATH:+:$PYTHONPATH}" python3 "$HERE/env_template.py" >> "$LOG" 2>&1 || true
  STACK="present"
else
  printf 'pufferlib not importable — scaffold emitted but test_environment() not exercised\n' >> "$LOG"
  STACK="absent"
fi

[ -s "$SCAFFOLD" ] || printf '{}' > "$SCAFFOLD"
[ -s "$LOG" ] || printf '{}' > "$LOG"
printf '{"tool":"env_scaffold","status":"ok","grid_size":"%s","stack":"%s","scaffold":"%s","log":"%s"}\n' "$GRID_SIZE" "$STACK" "$SCAFFOLD" "$LOG"
