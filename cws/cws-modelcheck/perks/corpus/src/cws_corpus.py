#!/usr/bin/env python3
"""cws_corpus — run a corpus of known-bad blueprints; assert the checker catches each defect.

The detector's proof: a model checker that never flags anything is useless. This runs every
`*.json` blueprint in CORPUS_DIR through `composer.structural` (deadlock = non-terminal sink,
unreachable state, no reachable terminal) and asserts EACH is detected. A `missed` case is a hole in
the checker — the run fails and names it.

Reads CORPUS_DIR + RECORD_STORE from env; writes RECORD_STORE/corpus.json + one structured JSON line.
Exit 0 iff every case was caught (and the corpus was non-empty).
"""
from __future__ import annotations
import json
import os
import sys

# Locate the cyberware repo root (the dir holding infra/govern): prefer CYBERWARE_ROOT (needed when the
# chip is vendored outside the tree, e.g. CLOUD_MODE), else ascend from this file (in-tree submodule).
_root = os.environ.get("CYBERWARE_ROOT")
if not (_root and os.path.isdir(os.path.join(_root, "infra", "govern"))):
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "govern")):
        _d = os.path.dirname(_d)
    _root = _d
if os.path.isdir(os.path.join(_root, "infra", "govern")):
    sys.path.insert(0, _root)

from infra.govern import composer  # noqa: E402


def main() -> int:
    corpus_dir = os.environ["CORPUS_DIR"]
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "corpus.json")
    os.makedirs(store, exist_ok=True)

    cases, caught, missed = [], 0, []
    for fn in sorted(os.listdir(corpus_dir)):
        if not fn.endswith(".json"):
            continue
        bp = json.load(open(os.path.join(corpus_dir, fn)))
        issues = composer.structural(bp)
        if issues:
            caught += 1
        else:
            missed.append(fn)
        cases.append({"case": fn, "detected": bool(issues), "issues": issues})

    total = len(cases)
    ok = total > 0 and not missed
    report = {"corpus_dir": corpus_dir, "cases": total, "caught": caught, "missed": missed,
              "status": "ok" if ok else "fail", "detail": cases}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_corpus", "status": report["status"], "cases": total,
                      "caught": caught, "missed": len(missed), "report": out}))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
