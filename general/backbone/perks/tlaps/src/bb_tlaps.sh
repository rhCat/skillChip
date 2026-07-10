#!/usr/bin/env bash
# bb_tlaps — porter: runs the Python core (bb_tlaps.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/bb_tlaps.py"
