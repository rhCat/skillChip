#!/usr/bin/env bash
# chaos_drill — V-CHAOS drill.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/chaos_drill.py"
