#!/usr/bin/env bash
# chaos_partition — V-CHAOS drill.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/chaos_partition.py"
