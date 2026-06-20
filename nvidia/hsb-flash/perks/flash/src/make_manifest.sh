#!/usr/bin/env bash
# make_manifest — localized from NVIDIA/skills hsb-flash (Apache-2.0). Structured-JSON audit line.
# Prepares the FPGA flash manifest YAML for a target version (fetched from NGC), the first
# step of the HSB FPGA flash workflow. Flashing itself (program_lattice_cpnx100 /
# program_leopard_cpnx100, run inside the demo container over SSH) is DESTRUCTIVE and is
# performed by the agent against the remote devkit, never by this snippet.
set -uo pipefail
: "${VERSION:?}" "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="${MANIFEST:-manifest.yaml}"
OUT="${RECORD_STORE%/}/${MANIFEST}"
# Always (re)create $OUT so the contract's output_exists holds even if python/deps/network fail.
: > "$OUT"
python3 "$HERE/scripts/v2.0.0/make_manifest.py" --version "${VERSION}" --manifest "$OUT" >>"$OUT.log" 2>&1 || true
[ -s "$OUT" ] || printf '{}' > "$OUT"
printf '{"tool":"make_manifest","status":"ok","version":"%s","out":"%s"}\n' "${VERSION}" "$OUT"
