#!/usr/bin/env python3
"""cws_quickstart — conformance check: a quickstart DOC must document a REAL, RUNNABLE governed claim.

'Documentation is redeemed, not asserted' applies to a quickstart too: a quickstart that shows a claim
against a skill that doesn't exist (or was renamed) is a broken promise. This perk extracts the ONE
governed claim from the quickstart markdown (a fenced ```json block naming skill + perk) and proves it is
well-formed and — when a CATALOG (a /catalog JSON) is provided — that its skill + perk RESOLVE in the
governed catalog. This is a DRY replay: it proves the documented claim WOULD run (shape + resolution),
without firing it (a live end-to-end fire needs a govd session + token, out of a confined step's reach).

Reads DOC (required) + optional CATALOG + RECORD_STORE from env; writes RECORD_STORE/quickstart.json + one
JSON line. Exit 0 iff the doc documents a valid, resolvable claim, else 1.
"""
from __future__ import annotations
import json
import os
import re
import sys

CLAIM_KEYS = {"skill", "perk"}


def _extract_claims(md):
    """Every fenced ```json block that parses to an object naming a skill + perk (a governed claim)."""
    claims = []
    for m in re.finditer(r"```(?:json)?\s*\n(.*?)```", md, re.DOTALL):
        try:
            obj = json.loads(m.group(1))
        except Exception:
            continue
        if isinstance(obj, dict) and CLAIM_KEYS <= set(obj):
            claims.append(obj)
    return claims


def _catalog_index(cat):
    """skill -> set(perk) from a /catalog JSON (a list, or {skills:[...]})."""
    sk = cat.get("skills", cat) if isinstance(cat, dict) else cat
    idx = {}
    for s in sk:
        name = s.get("skill") or s.get("name")
        perks = [(p.get("perk") or p.get("id") or p.get("name")) if isinstance(p, dict) else p
                 for p in (s.get("perks") or [])]
        if name:
            idx[name] = set(perks)
    return idx


def main() -> int:
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "quickstart.json")
    os.makedirs(store, exist_ok=True)
    doc = os.environ.get("DOC", "")

    def emit(obj, code):
        json.dump(obj, open(out, "w"), indent=2)
        print(json.dumps({k: obj[k] for k in ("tool", "status", "claim", "resolves", "reason") if k in obj}))
        return code

    if not doc or not os.path.isfile(doc):
        return emit({"tool": "cws_quickstart", "status": "fail", "reason": f"DOC not a file: {doc}"}, 1)
    md = open(doc, encoding="utf-8").read()
    claims = _extract_claims(md)
    if len(claims) != 1:
        return emit({"tool": "cws_quickstart", "status": "fail", "claim_count": len(claims),
                     "reason": f"expected exactly ONE governed claim block, found {len(claims)}"}, 1)
    claim = claims[0]
    result = {"tool": "cws_quickstart", "doc": os.path.basename(doc),
              "claim": {"skill": claim.get("skill"), "perk": claim.get("perk")}, "claim_valid": True}

    resolves = None
    cat_path = os.environ.get("CATALOG", "")
    if cat_path:   # CATALOG set -> it MUST be a readable, valid catalog (fail-closed, no silent skip)
        if not os.path.isfile(cat_path):
            return emit({"tool": "cws_quickstart", "status": "fail",
                         "reason": f"CATALOG set but not a file: {cat_path}"}, 1)
        try:
            cat = json.load(open(cat_path))
        except Exception as e:
            return emit({"tool": "cws_quickstart", "status": "fail",
                         "reason": f"CATALOG is not valid JSON: {e}"}, 1)
        idx = _catalog_index(cat)
        s, p = claim.get("skill"), claim.get("perk")
        resolves = s in idx and p in idx.get(s, set())
        result["resolves"] = resolves
        result["catalog_skills"] = len(idx)

    ok = result["claim_valid"] and (resolves is not False)   # catalog given -> must resolve; else shape-only
    result["status"] = "ok" if ok else "fail"
    if resolves is False:
        result["reason"] = f"documented claim {claim.get('skill')}/{claim.get('perk')} does not resolve in the catalog"
    return emit(result, 0 if ok else 1)


if __name__ == "__main__":
    sys.exit(main())
