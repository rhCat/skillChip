#!/usr/bin/env bash
# sys_stat — porter: governed host system metrics (CPU/load/mem/uptime).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/sys_stat.py"
