#!/usr/bin/env bash
# bench_microvm_overhead porter
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/bench_microvm_overhead.py"
