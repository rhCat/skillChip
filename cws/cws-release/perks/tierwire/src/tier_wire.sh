#!/usr/bin/env bash
# tier_wire — porter: P3-T11 tier→sandbox-profile wiring validator (backend selection enforced at the grant).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/tier_wire.py"
