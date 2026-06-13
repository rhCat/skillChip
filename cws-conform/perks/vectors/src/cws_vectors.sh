#!/usr/bin/env bash
# cws_vectors — porter: runs the Python core, which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/cws_vectors.py"
