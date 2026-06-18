#!/usr/bin/env bash
# cws_release_publish — porter: runs the Python core.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/cws_release_publish.py"
