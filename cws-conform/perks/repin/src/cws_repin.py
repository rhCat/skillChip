#!/usr/bin/env python3
"""cws_repin — re-pin a chip's authenticity under canonical hashing (the SV-1 self-referential act).

cyberware's claim is "a specification, not a codebase": its identity is a hash anyone can reproduce. This
perk first OBSERVES drift — it verifies each skill's files against its *committed* index.json (the pins the
run did NOT produce), so a file changed since the last pin is named — then regenerates every per-skill
index + the chip manifest and records the old -> new `chip_sha` transition.

The falsifiable signal is `pre_drift`: skills whose committed index no longer matches their files.
`status: green` means the committed chip was already canonical (a no-op re-pin — the healthy steady state);
`status: drift` means the committed pins were stale and had to be rewritten. Either way the chip is left
re-pinned and the transition recorded; the exit code reflects whether the committed state was already clean
(the SV-1 gate: skill_index_check green + a recorded old->new transition).

Reads TARGET_CHIP + RECORD_STORE from env; writes RECORD_STORE/repin.json + one structured JSON line.
Exit 0 iff no pre-existing drift (the committed pins matched); nonzero iff the chip had drifted.
"""
from __future__ import annotations
import json
import os
import sys

# Locate the cyberware repo root (the dir holding infra/govern) so the validator can import the engine's
# own authenticity tool. Prefer an explicit CYBERWARE_ROOT (needed when the chip is vendored outside the
# tree, e.g. CLOUD_MODE), else ascend from this file (works for the in-tree submodule layout).
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra.tool import skill_index as si  # noqa: E402


def main() -> int:
    target = os.path.abspath(os.environ["TARGET_CHIP"])
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "repin.json")
    os.makedirs(store, exist_ok=True)

    skills = si.all_skills(target)

    # 1. OBSERVE drift against the COMMITTED pins, BEFORE regenerating — the falsifiable signal. A skill
    #    with no committed index yet is "new" (not drift); a committed index that no longer matches its
    #    files is drift the re-pin will have to rewrite.
    mp = os.path.join(target, si.MANIFEST)
    old_chip_sha = (json.load(open(mp)).get("chip_sha") if os.path.isfile(mp) else None)
    pre_drift, new_skills = [], []
    for s in skills:
        if os.path.isfile(os.path.join(target, s, si.INDEX)):
            ok, problems = si.verify(s, target)
            if not ok:
                pre_drift.append({"skill": s, "problems": problems[:5]})
        else:
            new_skills.append(s)

    # 2. RE-PIN — regenerate every index + the manifest under canonical hashing.
    for s in skills:
        si.write_index(s, target)
    manifest = si.write_manifest(target)
    new_chip_sha = manifest["chip_sha"]

    clean = not pre_drift                                       # green = the committed pins already matched
    record = {
        "target": target,
        "skills": len(skills),
        "new_skills": new_skills,
        "old_chip_sha": old_chip_sha,
        "new_chip_sha": new_chip_sha,
        "changed": old_chip_sha != new_chip_sha,
        "pre_drift": pre_drift,
        "drift_count": len(pre_drift),
        "skill_index_check": "green" if clean else "drift",
        "status": "green" if clean else "drift",
    }
    json.dump(record, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_repin", "status": record["status"], "skills": len(skills),
                      "drift": len(pre_drift), "old_chip_sha": (old_chip_sha or "")[:16],
                      "new_chip_sha": new_chip_sha[:16], "report": out}))
    return 0 if clean else 1


if __name__ == "__main__":
    sys.exit(main())
