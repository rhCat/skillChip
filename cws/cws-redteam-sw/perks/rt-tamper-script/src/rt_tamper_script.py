#!/usr/bin/env python3
"""rt_tamper_script — adversarial: edit a compiled script AFTER the executor snapshots it; confirm REFUSAL.

Software-tier red-team (SV-1/SV-2). The clean first run is accepted (oracle: it takes the .bk snapshot);
a post-snapshot edit must be refused (exit 4) with a tamper_refused event recorded. Exit 0 iff held."""
from __future__ import annotations
import hashlib
import json
import os
import shlex
import subprocess
import sys
import tempfile

_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

SCRIPT = r'''#!/usr/bin/env bash
set -uo pipefail
SNIP=__SNIP__
RECORD_STORE=__REC__
mkdir -p "$RECORD_STORE"
step1() { echo "[step 1] s1"; bash "$SNIP/s1.sh" || exit $?; }
case "${1:-}" in
  --list) printf "1\ts1\n" ;;
  --step) shift; "step${1:?step}" ;;
  --all) step1 ;;
  *) echo usage >&2; exit 2 ;;
esac
'''


def _exec(script):
    return subprocess.run([sys.executable, "-m", "infra.govern.executor", "--script", script, "--all"],
                          cwd=_root, env={**os.environ, "CYBERWARE_ROOT": _root}, capture_output=True, text=True)


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "redteam.json")
    os.makedirs(store, exist_ok=True)
    sb = tempfile.mkdtemp(prefix="rt-tamper-")
    # P1-T06: a faithful compiled script is backed by a perk dir whose manifesto is blessed in index.json
    # (the executor authenticates it before declaring steps). The clean-run oracle needs a REAL step to run,
    # so build the perk closure; the attack edits run.sh, which the tamper-check catches before step derivation.
    src = os.path.join(sb, "chip", "sk", "perks", "pk", "src")
    os.makedirs(src)
    porter = os.path.join(src, "s1.sh")
    open(porter, "w").write("#!/usr/bin/env bash\necho ok\n")
    mbody = json.dumps({"sequence": ["s1"]}).encode()
    open(os.path.join(sb, "chip", "sk", "perks", "pk", "manifesto.json"), "wb").write(mbody)
    open(os.path.join(sb, "chip", "sk", "index.json"), "w").write(json.dumps({"files": {
        "perks/pk/src/s1.sh": hashlib.sha256(open(porter, "rb").read()).hexdigest(),
        "perks/pk/manifesto.json": hashlib.sha256(mbody).hexdigest()}}))
    rec = os.path.join(sb, "rec")
    script = os.path.join(sb, "run.sh")
    open(script, "w").write(SCRIPT.replace("__SNIP__", shlex.quote(src)).replace("__REC__", shlex.quote(rec)))
    clean = _exec(script)
    clean_accepted = clean.returncode == 0
    open(script, "a").write("\n# adversarial edit after snapshot\n")
    attack = _exec(script)
    refused = attack.returncode == 4 and "TAMPER" in attack.stdout
    led = os.path.join(rec, "run-ledger.json")
    recorded = os.path.isfile(led) and any(r.get("event") == "tamper_refused"
                                           for r in json.load(open(led)).get("runs", []))
    held = clean_accepted and refused and recorded
    json.dump({"perk": "rt-tamper-script", "attack": "edit a compiled script after the executor snapshot",
               "boundary": "infra.govern.executor tamper check (exit 4, SV-1 software boundary)",
               "clean_accepted": clean_accepted, "refused": refused, "refusal_recorded": recorded,
               "boundary_held": held}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "rt_tamper_script", "status": "held" if held else "BREACH", "report": out}))
    return 0 if held else 1


if __name__ == "__main__":
    sys.exit(main())
