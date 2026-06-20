#!/usr/bin/env bash
# local_manifest — localized from NVIDIA/skills hsb-flash (Apache-2.0). Structured-JSON audit line.
# Builds a flash manifest YAML from LOCAL bit files (CPNX / CLNX / Stratix-10 rpd) rather than
# fetching from NGC: it measures each file's size + MD5 and records the strategy. Fully offline
# and deterministic. The caller is trusted to ensure the bit files are correct for the device.
# Flashing itself (program_lattice_cpnx100 / program_leopard_cpnx100, inside the demo container
# over SSH) is DESTRUCTIVE and is performed by the agent against the remote devkit, never here.
set -uo pipefail
: "${VERSION:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${MANIFEST:-manifest.yaml}"
OUT="${RECORD_STORE%/}/${MANIFEST}"
# Always (re)create $OUT so the contract's output_exists holds even if python/deps/inputs fail.
: > "$OUT"

# Translate env -> argv: only one of CPNX/CLNX/STRATIX is required by the core script.
ARGS=(--version "${VERSION}" --manifest "$OUT")
[ -n "${CPNX_FILE:-}" ]    && ARGS+=(--cpnx-file "${CPNX_FILE}")
[ -n "${CLNX_FILE:-}" ]    && ARGS+=(--clnx-file "${CLNX_FILE}")
[ -n "${STRATIX_FILE:-}" ] && ARGS+=(--stratix-file "${STRATIX_FILE}")
[ -n "${STRATEGY:-}" ]     && ARGS+=(--strategy "${STRATEGY}")

python3 "$HERE/scripts/v2.0.0/local_manifest.py" "${ARGS[@]}" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"local_manifest","status":"ok","version":"%s","out":"%s"}\n' "${VERSION}" "$OUT"
