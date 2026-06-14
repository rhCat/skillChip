#!/usr/bin/env bash
# rt_grant_forged porter
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/rt_grant_forged.py"
