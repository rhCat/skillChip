#!/usr/bin/env python3
"""bb_tlaps — backbone layer 3: generate the TLAPS proof spec and discharge it with tlapm.

Env: TARGET_BLUEPRINT, RECORD_STORE; optional TLAPM_TIMEOUT (seconds, default 240).
Output: ${RECORD_STORE}/backbone_tlaps.json — {"tool","blueprint","status","obligations","detail","error"}.
Proof artifacts (the generated <id>_proofs.tla + tlapm cache) live under ${RECORD_STORE}/tlaps_work.

Fail-closed: a missing `tlapm` is status=fail, never a silent skip.
Known toolchain gotcha (encoded here so callers never hit it): the lpp generator names the
module `<id>_proofs` but writes `<id>_proof.tla` — tlapm requires filename == module name,
so the spec is copied to the matching filename before proving.
"""
import json
import os
import re
import shutil
import subprocess
import sys


def tlaps_layer(path: str, timeout: int, workdir: str) -> dict:
    if shutil.which("tlapm") is None:
        return {"status": "fail", "obligations": 0, "detail": [],
                "error": "missing_tool: tlapm not on PATH (fail-closed)"}
    try:
        bp_id = json.load(open(path)).get("id") or "blueprint"
    except Exception as e:
        return {"status": "fail", "obligations": 0, "detail": [], "error": f"unreadable JSON: {e}"}
    os.makedirs(workdir, exist_ok=True)
    from lpp.util.tlaps_prover import run as tlaps_generate
    gen = tlaps_generate({"blueprintPath": path, "outputDir": workdir, "verify": False})
    ctx = gen.get("context", {})
    spec = ctx.get("tlaSpec")
    if not spec or ctx.get("error"):
        return {"status": "fail", "obligations": 0, "detail": [],
                "error": "proof generation failed: %s" % ctx.get("error")}
    fixed = os.path.join(workdir, "%s_proofs.tla" % bp_id)  # filename must match the module name
    shutil.copy(spec, fixed)
    try:
        r = subprocess.run(["tlapm", "--cleanfp", os.path.basename(fixed)],
                           capture_output=True, text=True, timeout=timeout, cwd=workdir)
    except subprocess.TimeoutExpired:
        return {"status": "fail", "obligations": 0, "detail": [],
                "error": "tlapm timeout after %ss" % timeout}
    text = r.stdout + r.stderr
    # tlapm prints a per-module summary; the FIRST "All 0 obligation proved" line is the
    # TLAPS stdlib module — the target module's summary is the LAST match. A gate must not
    # false-pass on the preamble: require exit 0, no failed-obligations line, and take the
    # last proved-count.
    failed = re.search(r"(\d+)/(\d+) obligations? failed", text)
    proved_all = re.findall(r"All (\d+) obligations? proved", text)
    tail = [l for l in text.strip().splitlines() if l.strip()][-8:]
    if failed or r.returncode != 0:
        err = ("%s/%s obligations failed" % (failed.group(1), failed.group(2))
               if failed else "tlapm exited %s" % r.returncode)
        return {"status": "fail", "obligations": 0, "detail": tail, "error": err}
    if not proved_all:
        return {"status": "fail", "obligations": 0, "detail": tail,
                "error": "no proved-obligations summary in tlapm output"}
    return {"status": "ok", "obligations": int(proved_all[-1]), "detail": [], "error": None}


def main() -> int:
    target = os.environ["TARGET_BLUEPRINT"]
    store = os.environ["RECORD_STORE"]
    timeout = int(os.environ.get("TLAPM_TIMEOUT", "240"))
    os.makedirs(store, exist_ok=True)
    res = {"tool": "bb_tlaps", "blueprint": target}
    res.update(tlaps_layer(target, timeout, os.path.join(store, "tlaps_work")))
    out = os.path.join(store, "backbone_tlaps.json")
    with open(out, "w") as f:
        json.dump(res, f, indent=1)
        f.write("\n")
    print(json.dumps({"tool": "bb_tlaps", "status": res["status"],
                      "obligations": res["obligations"], "out": out}))
    return 0 if res["status"] == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
