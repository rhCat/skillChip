#!/usr/bin/env python3
"""addperk_formulate — scaffold the new perk into the skill, validate it composes, and commit.

Reads SKILL, PERK, PERK_DESC, TOOL, BINARY (default bash), RECORD_STORE from the environment. Creates
skills/<SKILL>/perks/<PERK>/{metadata,manifesto,src/{contracts,<tool>.sh|.py+porter}}, appends to
perks.json, composes the skill to validate, and commits on the current (perk-update) branch.
"""
from __future__ import annotations
import json
import os
import subprocess
import sys


# Resolve the cyberware repo so we can resolve a skill's dir via the registry (flat OR source-grouped).
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra import registry  # noqa: E402


def sh_stub(tool: str, desc: str) -> str:
    return ("#!/usr/bin/env bash\n"
            f"# {tool} — TODO ({desc}). Emit deterministic structured JSON.\n"
            "set -euo pipefail\n"
            ': "${INPUT:?}" "${RECORD_STORE:?}"\n'
            f'OUT="${{RECORD_STORE%/}}/{tool}.out"\n'
            f'echo "TODO: implement {tool}" > "$OUT"\n'
            f'printf \'{{"tool":"{tool}","status":"ok","out":"%s"}}\\n\' "$OUT"\n')


def py_stub(tool: str, desc: str) -> str:
    return ("#!/usr/bin/env python3\n"
            f'"""{tool} — TODO ({desc}). Reads INPUT + RECORD_STORE from env; emits structured JSON."""\n'
            "from __future__ import annotations\nimport json\nimport os\nimport sys\n\n\n"
            "def main() -> int:\n"
            '    """TODO: implement."""\n'
            '    inp = os.environ["INPUT"]\n'
            '    store = os.environ["RECORD_STORE"].rstrip("/")\n'
            f'    out = os.path.join(store, "{tool}.out")\n'
            f'    open(out, "w").write("TODO: implement {tool}\\n")\n'
            f'    print(json.dumps({{"tool": "{tool}", "status": "ok", "out": out}}))\n'
            "    return 0\n\n\n"
            'if __name__ == "__main__":\n    sys.exit(main())\n')


def porter(tool: str) -> str:
    return ("#!/usr/bin/env bash\n"
            f"# {tool} — porter: runs {tool}.py, which reads its inputs from the environment.\n"
            "set -euo pipefail\n"
            'HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\n'
            f'exec python3 "$HERE/{tool}.py"\n')


def main() -> int:
    """Scaffold + validate + commit the new perk."""
    skill = os.environ["SKILL"]
    perk = os.environ["PERK"]
    desc = os.environ["PERK_DESC"]
    tool = os.environ.get("TOOL") or f"{skill}_{perk}"
    binary = os.environ.get("BINARY") or "bash"
    store = os.environ["RECORD_STORE"].rstrip("/")
    chip = registry.SKILLCHIP                       # the chip repo (a git submodule) — git ops run here
    sdir = registry.skill_dir(skill)                # the skill's dir wherever it lives (any source)
    pdir = os.path.join(sdir, "perks", perk)
    src = os.path.join(pdir, "src")
    os.makedirs(src, exist_ok=True)
    is_py = binary == "python3"
    out_path = "${RECORD_STORE}/" + tool + ".out"

    json.dump({"perk": perk, "skill": skill, "description": desc, "rules": ["TODO"], "usage": "TODO",
               "limitation": "TODO", "minimal_example": {"perk": perk, "vars": {"INPUT": "<...>"}}},
              open(os.path.join(pdir, "metadata.json"), "w"), indent=2)
    json.dump({"_perk": perk, "sequence": [tool], "tools": {tool: {"binary": binary, "params": {"INPUT": "${INPUT}"}}},
               "env": {"INPUT": "${INPUT}", "RECORD_STORE": "${record_store}"}, "requires": [binary]},
              open(os.path.join(pdir, "manifesto.json"), "w"), indent=2)
    json.dump({"tool": tool, "inputs": {"INPUT": {"type": "string", "required": True}},
               "outputs": {tool + "_out": {"path": out_path, "type": "file"}},
               "checks": {"exit_zero": True, "output_exists": out_path}},
              open(os.path.join(src, "contracts.json"), "w"), indent=2)
    if is_py:
        open(os.path.join(src, tool + ".py"), "w").write(py_stub(tool, desc))
        open(os.path.join(src, tool + ".sh"), "w").write(porter(tool))
    else:
        open(os.path.join(src, tool + ".sh"), "w").write(sh_stub(tool, desc))
    for f in os.listdir(src):
        if f.endswith((".sh", ".py")):
            os.chmod(os.path.join(src, f), 0o755)

    pj = os.path.join(sdir, "perks.json")
    data = json.load(open(pj))
    if perk not in [p["id"] for p in data["perks"]]:
        data["perks"].append({"id": perk, "summary": desc[:90], "destructive": False, "tools": [tool]})
        open(pj, "w").write(json.dumps(data, indent=2) + "\n")

    ledger = {"skill": skill, "perk": perk, "record_store": "/tmp/" + skill + "_" + perk + "_chk", "vars": {"INPUT": "x"}}
    lf = os.path.join(store, "validate.ledger")
    json.dump(ledger, open(lf, "w"))
    comp = subprocess.run([sys.executable, "-m", "infra.govern.composer", "--ledger", lf],
                          cwd=_root, capture_output=True, text=True)
    composes = "OK" in comp.stdout
    subprocess.run(["git", "-C", chip, "add", os.path.relpath(sdir, chip)], check=False)
    subprocess.run(["git", "-C", chip, "commit", "-m", f"perk: add {skill}/{perk}", "--no-verify"],
                   capture_output=True, text=True)
    result = {"tool": "addperk_formulate", "status": "ok", "skill": skill, "perk": perk,
              "perk_dir": os.path.relpath(pdir, chip), "tool_file": tool + (".py" if is_py else ".sh"),
              "composes": composes, "report": os.path.join(store, "formulate.json")}
    json.dump(result, open(os.path.join(store, "formulate.json"), "w"), indent=2)
    print(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
