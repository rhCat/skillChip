#!/usr/bin/env bash
# rt_grant_replay porter — runs the Python core, which mounts the attack through exod+sandbox and reports.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/rt_grant_replay.py"
