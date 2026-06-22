#!/usr/bin/env python3
"""rt_snippet_toctou — adversarial: mutate a perk porter AFTER blessing; confirm the per-step check REFUSES.

Software-tier red-team (SV-1/SV-2, the P1-T05 surface). A clean step runs (oracle); a post-bless mutation
of the porter is refused at exactly that step (exit 8) with a snippet_refused event. Exit 0 iff held."""
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
# COMPILED by cyberware . skill=sk perk=pk
SNIP=__SNIP__
RECORD_STORE=__REC__
mkdir -p "$RECORD_STORE"
step1() { echo "[step 1] tool"; bash "$SNIP/tool.sh" || exit $?; }
case "${1:-}" in
  --list) printf "1\ttool\n" ;;
  --step) shift; "step${1:?step}" ;;
  --all) step1 ;;
  *) echo usage >&2; exit 2 ;;
esac
'''


def _exec(script, step):
    return subprocess.run([sys.executable, "-m", "infra.govern.executor", "--script", script, "--step", step],
                          cwd=_root, env={**os.environ, "CYBERWARE_ROOT": _root}, capture_output=True, text=True)


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "redteam.json")
    os.makedirs(store, exist_ok=True)
    sb = tempfile.mkdtemp(prefix="rt-snippet-")
    src = os.path.join(sb, "chip", "sk", "perks", "pk", "src")
    os.makedirs(src)
    porter = os.path.join(src, "tool.sh")
    open(porter, "w").write("#!/usr/bin/env bash\necho ok\n")
    digest = hashlib.sha256(open(porter, "rb").read()).hexdigest()
    # P1-T06: the executor derives the step set from the perk's manifesto sequence (the blessed plan), not
    # the script's --list, and AUTHENTICATES the manifesto against its blessed sha — so a faithful mock ships
    # the manifesto AND blesses its sha in index.json. (Without it the run fails CLOSED: no declared step,
    # nothing executes — a held boundary, but not THIS attack's oracle.)
    mbody = json.dumps({"sequence": ["tool"]}).encode()
    open(os.path.join(sb, "chip", "sk", "perks", "pk", "manifesto.json"), "wb").write(mbody)
    open(os.path.join(sb, "chip", "sk", "index.json"), "w").write(json.dumps({"files": {
        "perks/pk/src/tool.sh": digest,
        "perks/pk/manifesto.json": hashlib.sha256(mbody).hexdigest()}}))
    rec = os.path.join(sb, "rec")
    script = os.path.join(sb, "run.sh")
    open(script, "w").write(SCRIPT.replace("__SNIP__", shlex.quote(src)).replace("__REC__", shlex.quote(rec)))
    clean = _exec(script, "1")
    clean_accepted = clean.returncode == 0
    open(porter, "a").write("# post-bless mutation\n")
    attack = _exec(script, "1")
    refused = attack.returncode == 8 and "SNIPPET" in attack.stdout
    led = os.path.join(rec, "run-ledger.json")
    recorded = os.path.isfile(led) and any(r.get("event") == "snippet_refused"
                                           for r in json.load(open(led)).get("runs", []))
    # P1-T06 variant — the manifesto-decouple attack: swap the sibling manifesto so the step->tool map names
    # a tool NOT in the blessed set (snippet-verify would then look for the wrong file, silently no-op) while
    # the wrapper still runs the (already-mutated) porter. The executor authenticates the manifesto against
    # its blessed sha, so the swap yields no declared steps and the tampered porter NEVER runs.
    open(porter, "w").write('#!/usr/bin/env bash\necho INJECTED_VIA_MANIFEST_SWAP\n')
    open(os.path.join(sb, "chip", "sk", "perks", "pk", "manifesto.json"), "w").write(
        json.dumps({"sequence": ["renamed_so_snippet_check_misses"]}))
    swap = _exec(script, "1")
    swap_refused = swap.returncode != 0 and "INJECTED_VIA_MANIFEST_SWAP" not in swap.stdout
    held = clean_accepted and refused and recorded and swap_refused
    json.dump({"perk": "rt-snippet-toctou", "attack": "mutate a perk porter after blessing (+ manifest swap)",
               "boundary": "infra.govern.snippetverify + plan_steps manifest auth via executor (SV-2)",
               "clean_accepted": clean_accepted, "refused": refused, "refusal_recorded": recorded,
               "manifest_swap_refused": swap_refused, "boundary_held": held}, open(out, "w"), indent=2)
    print(json.dumps({"tool": "rt_snippet_toctou", "status": "held" if held else "BREACH", "report": out}))
    return 0 if held else 1


if __name__ == "__main__":
    sys.exit(main())
