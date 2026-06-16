#!/usr/bin/env bash
# cws_labeling — porter: runs the Python core.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/cws_labeling.py"
