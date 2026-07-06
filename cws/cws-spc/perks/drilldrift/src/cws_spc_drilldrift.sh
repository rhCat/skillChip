#!/usr/bin/env bash
# cws_spc_drilldrift — porter: runs the Python core (cws_spc_drilldrift.py), which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/cws_spc_drilldrift.py"
