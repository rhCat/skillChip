#!/usr/bin/env bash
# hermes_exec — the headless agent's terminal, as a GOVERNED confined action.
#
# exod already runs this snippet in a confined sandbox: no network (--unshare-net),
# dropped privileges, and only /usr /bin /lib* /etc + the cargo workspace bound in. So a
# host-wide `rm -rf /` is already inert here — nothing but the bound workspace is real.
# This snippet's job is the second, un-liftable layer: a DESTRUCTIVE FLOOR that runs
# BEFORE the command, in the blessed (hash-verified) chip code, so no agent-side
# yolo/permission mode can lift it. The agent supplies only var VALUES (CMD/WORKDIR/…);
# it never edits this file.
#
# The floor itself lives in hermes_floor.sh as a PURE predicate (floor_verdict), and
# hermes_floor_check self-tests it against the pinned case table as step 1 of this perk —
# this file is the ONLY place in the perk that executes anything, and it does so strictly
# after the floor allows. NEVER run this file outside the confined sandbox: the floor is
# defense-in-depth, confinement is the guarantee.
#
# Contract:
#   CMD          (required)  the command line to run
#   WORKDIR      (required)  cwd for the command — MUST resolve inside the
#                            cargo workspace (the agent's scoped rw dir)
#   RECORD_STORE (exod)      server-side workspace root (cargo mount)
#   OUT          (optional)  path under RECORD_STORE for stdout+stderr capture
# Output: JSON status line; captured output at $OUT (default $RECORD_STORE/exec.out).
set -euo pipefail

: "${CMD:?CMD required}" "${RECORD_STORE:?}"
WORKDIR="${WORKDIR:-$RECORD_STORE}"
OUT="${OUT:-${RECORD_STORE%/}/exec.out}"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hermes_floor.sh"

emit_block() {  # $1 = reason
  printf '{"tool":"hermes_exec","status":"blocked","floor":"%s"}\n' "$1"
  exit 3
}

# --- The destructive floor -------------------------------------------------
verdict="$(floor_verdict "$CMD")" || emit_block "${verdict#block:}"

# --- Guard the workspace boundary -----------------------------------------
# WORKDIR must be inside the cargo workspace. Refuse cwd escapes.
realwd="$(cd "$WORKDIR" 2>/dev/null && pwd -P || true)"
realroot="$(cd "$RECORD_STORE" 2>/dev/null && pwd -P || true)"
if [[ -z "$realwd" || -z "$realroot" ]] ||
   [[ "$realwd" != "$realroot" && "${realwd}/" != "${realroot}/"* ]]; then
  emit_block "WORKDIR outside the cargo workspace"
fi

# --- Run the command, confined, capturing output to cargo -----------------
set +e
( cd "$realwd" && bash -c "$CMD" ) >"$OUT" 2>&1
rc=$?
set -e

printf '{"tool":"hermes_exec","status":"ok","exit":%d,"workdir":"%s","out":"%s","bytes":%d}\n' \
  "$rc" "$realwd" "$OUT" "$(wc -c < "$OUT" 2>/dev/null || echo 0)"
