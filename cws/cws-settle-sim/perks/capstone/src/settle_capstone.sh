#!/usr/bin/env bash
# settle_capstone
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/settle_capstone.py"
