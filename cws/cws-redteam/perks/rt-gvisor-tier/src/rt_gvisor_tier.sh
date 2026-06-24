#!/usr/bin/env bash
# rt_gvisor_tier — porter: P2-T04 community-tier gVisor seam + no-secrets floor red-team check.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/rt_gvisor_tier.py"
