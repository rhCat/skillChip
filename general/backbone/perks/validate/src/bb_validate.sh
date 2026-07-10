#!/usr/bin/env bash
# bb_validate — porter: runs the Python core (bb_validate.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/bb_validate.py"
