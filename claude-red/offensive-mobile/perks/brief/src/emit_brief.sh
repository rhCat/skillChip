#!/usr/bin/env bash
# emit_brief — localized from SnailSploit/Claude-Red (MIT). Read-only: renders the vendored
# offensive-security METHODOLOGY (public, educational) to a record artifact. Creates nothing else.
set -uo pipefail
: "${RECORD_STORE:?}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${RECORD_STORE%/}/brief.md"
: > "$OUT"
cat "$HERE/methodology.md" >> "$OUT" 2>/dev/null || true
[ -s "$OUT" ] || printf '# methodology unavailable\n' > "$OUT"
printf '{"tool":"emit_brief","status":"ok","out":"%s"}\n' "$OUT"
