#!/usr/bin/env python3
"""cws_doclint — structural conformance lint for a spec document (the plan's P0-V10).

Makes "the specs exist and say something normative" a checkable claim rather than an assertion: it
confirms a spec file exists and is non-empty, renders as standalone Markdown (has a title), carries at
least MIN_NORMATIVE RFC-2119 normative statements (MUST / MUST NOT / SHALL / SHALL NOT / REQUIRED), and
mentions every REQUIRED topic. It is the buildable-now half of cws-conform — a parse, no infra — so the
P0 spec tranche can be redeemed (the cross-language vector replay is the separate `vectors` perk).

Reads from env: SPEC (path), optional MIN_NORMATIVE (default 1), optional REQUIRE (a ';'-separated list
of substrings that must each appear), RECORD_STORE. Writes RECORD_STORE/doclint.json + one JSON line.
Exit 0 iff the spec exists, has a title, meets MIN_NORMATIVE, and is missing no required topic.
"""
from __future__ import annotations
import json
import os
import re
import sys

NORMATIVE = re.compile(r"\b(MUST NOT|MUST|SHALL NOT|SHALL|REQUIRED)\b")


def main() -> int:
    spec = os.environ["SPEC"]
    min_normative = int(os.environ.get("MIN_NORMATIVE", "1"))
    require = [s.strip() for s in os.environ.get("REQUIRE", "").split(";") if s.strip()]
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "doclint.json")
    os.makedirs(store, exist_ok=True)

    exists = os.path.isfile(spec)
    body = open(spec).read() if exists else ""
    lines = body.splitlines()
    title = next((ln for ln in lines if ln.lstrip().startswith("#")), None)
    normative_count = len(NORMATIVE.findall(body))
    missing_required = [r for r in require if r not in body]

    problems = []
    if not exists:
        problems.append(f"missing: {spec}")
    elif not body.strip():
        problems.append("empty spec")
    if exists and not title:
        problems.append("no Markdown title (a line starting with #)")
    if exists and normative_count < min_normative:
        problems.append(f"only {normative_count} normative statement(s) < MIN_NORMATIVE {min_normative}")
    if missing_required:
        problems.append(f"missing required topic(s): {missing_required}")

    status = "ok" if not problems else "fail"
    report = {"spec": spec, "exists": exists, "lines": len(lines),
              "title": (title.strip() if title else None), "normative_count": normative_count,
              "min_normative": min_normative, "missing_required": missing_required,
              "problems": problems, "status": status}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_doclint", "status": status, "normative": normative_count,
                      "problems": len(problems), "report": out}))
    return 0 if status == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
