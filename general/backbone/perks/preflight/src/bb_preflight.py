#!/usr/bin/env python3
"""bb_preflight — the full backbone matrix over a directory of L++ blueprints.

Env: TARGET_DIR (searched recursively for lpp/v0.2.0 blueprint JSONs), RECORD_STORE;
optional TLC_TIMEOUT (default 120), TLAPM_TIMEOUT (default 240).
Output: ${RECORD_STORE}/backbone_preflight.json —
  {"tool","dir","results":[{file,validate,tlc,tlaps,obligations}...],
   "summary":{"total","pass","obligations"},"status"}.

The gate semantics (spec-first development, Emerald 1.1b): status=ok ONLY when every
discovered blueprint passes validate + TLC + TLAPS. An empty discovery is a FAIL —
a preflight that checked nothing must not read as a pass. Missing tools fail closed.
"""
import json
import os
import re
import shutil
import subprocess
import sys


def is_lpp_blueprint(path):
    try:
        d = json.load(open(path))
    except Exception:
        return False
    return isinstance(d, dict) and str(d.get("$schema", "")).startswith("lpp/")


def discover(root):
    hits = []
    for dirpath, _dirs, files in os.walk(root):
        for fn in sorted(files):
            if fn.endswith(".json"):
                p = os.path.join(dirpath, fn)
                if is_lpp_blueprint(p):
                    hits.append(p)
    return hits


def validate_layer(path):
    from lpp.core import load_blueprint
    try:
        raw = json.load(open(path))
    except Exception as e:
        return "fail", "unreadable JSON: %s" % e
    _bp, err = load_blueprint(raw)
    return ("fail", str(err)) if err else ("ok", None)


def tlc_layer(path, timeout):
    if shutil.which("tlc") is None:
        return "fail", "missing_tool: tlc"
    from lpp.core.validators.tla import validate_with_tlc
    ok, _msg = validate_with_tlc(json.load(open(path)), timeout=timeout)
    return ("ok", None) if ok else ("fail", "tlc_check_failed")


def tlaps_layer(path, timeout, workdir):
    if shutil.which("tlapm") is None:
        return "fail", 0, "missing_tool: tlapm"
    os.makedirs(workdir, exist_ok=True)
    from lpp.util.tlaps_prover import run as tlaps_generate
    bp_id = json.load(open(path)).get("id") or "blueprint"
    gen = tlaps_generate({"blueprintPath": path, "outputDir": workdir, "verify": False})
    spec = gen.get("context", {}).get("tlaSpec")
    if not spec or gen.get("context", {}).get("error"):
        return "fail", 0, "proof generation failed"
    fixed = os.path.join(workdir, "%s_proofs.tla" % bp_id)  # tlapm needs filename == module name
    shutil.copy(spec, fixed)
    try:
        r = subprocess.run(["tlapm", "--cleanfp", os.path.basename(fixed)],
                           capture_output=True, text=True, timeout=timeout, cwd=workdir)
    except subprocess.TimeoutExpired:
        return "fail", 0, "tlapm timeout"
    text = r.stdout + r.stderr
    failed = re.search(r"(\d+)/(\d+) obligations? failed", text)
    proved_all = re.findall(r"All (\d+) obligations? proved", text)  # last match = target module
    if failed or r.returncode != 0 or not proved_all:
        return "fail", 0, "unproved obligations"
    return "ok", int(proved_all[-1]), None


def main() -> int:
    root = os.environ["TARGET_DIR"]
    store = os.environ["RECORD_STORE"]
    tlc_t = int(os.environ.get("TLC_TIMEOUT", "120"))
    tlaps_t = int(os.environ.get("TLAPM_TIMEOUT", "240"))
    os.makedirs(store, exist_ok=True)

    blueprints = discover(root)
    results, total_obs = [], 0
    for p in blueprints:
        rel = os.path.relpath(p, root)
        v, verr = validate_layer(p)
        t, terr = (tlc_layer(p, tlc_t) if v == "ok" else ("skipped", "validate failed"))
        if v == "ok":
            a, obs, aerr = tlaps_layer(p, tlaps_t, os.path.join(store, "tlaps_work"))
        else:
            a, obs, aerr = "skipped", 0, "validate failed"
        total_obs += obs
        row = {"file": rel, "validate": v, "tlc": t, "tlaps": a, "obligations": obs,
               "errors": [e for e in (verr, terr, aerr) if e]}
        results.append(row)
        print(json.dumps({"file": rel, "validate": v, "tlc": t, "tlaps": a, "obligations": obs}))

    n_pass = sum(1 for r in results if r["validate"] == r["tlc"] == r["tlaps"] == "ok")
    status = "ok" if (blueprints and n_pass == len(results)) else "fail"
    if not blueprints:
        print(json.dumps({"tool": "bb_preflight", "error": "no lpp blueprints found under TARGET_DIR"}))
    report = {"tool": "bb_preflight", "dir": root, "results": results,
              "summary": {"total": len(results), "pass": n_pass, "obligations": total_obs},
              "status": status}
    out = os.path.join(store, "backbone_preflight.json")
    with open(out, "w") as f:
        json.dump(report, f, indent=1)
        f.write("\n")
    print(json.dumps({"tool": "bb_preflight", "status": status,
                      "total": len(results), "pass": n_pass, "obligations": total_obs, "out": out}))
    return 0 if status == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
