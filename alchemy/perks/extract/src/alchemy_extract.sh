#!/usr/bin/env bash
# alchemy_extract — porter: runs the Python core (the pinned putrefactio/alembic engines, file-mode).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/alchemy_extract.py"
