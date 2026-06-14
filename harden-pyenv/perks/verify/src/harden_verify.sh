#!/usr/bin/env bash
# harden_verify — porter: runs the Python core, which reads its inputs from the environment.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/harden_verify.py"
