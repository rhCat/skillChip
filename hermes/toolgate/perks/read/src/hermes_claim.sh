#!/usr/bin/env bash
# hermes_claim — record a VERDICT-ONLY effect-class claim. This perk never runs the
# claimed tool: Hermes executes its own handler after govd's allow; exod runs only
# this recorder. Everything here is value-free — TOOL (a name), ARGS_DIGEST (a
# sha256 fingerprint), TARGET (a coarse class label like path:<root> / host:<name>)
# — never argument values, never secrets. The effect class is the perk id, read
# from this file's own perk directory so the copies stay byte-identical.
set -euo pipefail
: "${TOOL:?}" "${ARGS_DIGEST:?}" "${TARGET:?}" "${RECORD_STORE:?}"

EFFECT="$(basename "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)")"
OUT="${RECORD_STORE%/}/claim.json"

jsan() { local s="$1"; s="${s//\\/}"; s="${s//\"/}"; printf '%s' "$s"; }

printf '{"tool":"hermes_claim","effect":"%s","claimed_tool":"%s","args_digest":"%s","target":"%s"}\n' \
  "$(jsan "$EFFECT")" "$(jsan "$TOOL")" "$(jsan "$ARGS_DIGEST")" "$(jsan "$TARGET")" | tee "$OUT"
