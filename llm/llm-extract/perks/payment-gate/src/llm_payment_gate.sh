#!/usr/bin/env bash
# llm_payment_gate — porter: P6-T09 llm/* schema-validation payment gate validator.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$HERE/llm_payment_gate.py"
