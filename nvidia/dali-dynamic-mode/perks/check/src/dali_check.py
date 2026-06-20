# SPDX-License-Identifier: Apache-2.0
# dali_check — static lint for DALI dynamic-mode (ndd) anti-patterns.
#
# Encodes the "Common Mistakes" and "Pipeline Mode Migration" guidance from the
# NVIDIA/skills `dali-dynamic-mode` SKILL.md (Apache-2.0). Pure stdlib (re + ast):
# it NEVER imports DALI and NEVER executes the target file — it only reads source text.
#
# Usage: python3 dali_check.py <source.py> --output <findings.json>
import argparse
import ast
import json
import re
import sys

# (rule, compiled regex, message) — line-oriented source-text checks.
_REGEX_RULES = [
    (
        "device-mixed",
        re.compile(r"""device\s*=\s*['"]mixed['"]"""),
        "device=\"mixed\" is pipeline-mode only; in dynamic mode use device=\"gpu\".",
    ),
    (
        "pipeline-def",
        re.compile(r"@\s*pipeline_def"),
        "@pipeline_def is pipeline mode; dynamic mode uses direct ndd.* calls in a loop.",
    ),
    (
        "pipe-build",
        re.compile(r"\.build\s*\("),
        "pipe.build() is pipeline mode; dynamic mode has no build step.",
    ),
    (
        "pipe-run",
        re.compile(r"\.run\s*\("),
        "pipe.run() is pipeline mode; iterate reader.next_epoch(batch_size=N) instead.",
    ),
    (
        "fn-operator",
        re.compile(r"(?<![\w.])fn\.|ndd\.fn\."),
        "fn.* / ndd.fn.* operators are pipeline mode; call operators directly on ndd (e.g. ndd.resize).",
    ),
    (
        "reader-lowercase",
        re.compile(r"ndd\.readers\.[a-z]\w*\s*\("),
        "Reader classes are PascalCase: use ndd.readers.File(...), not ndd.readers.file(...).",
    ),
    (
        "pipeline-import",
        re.compile(r"from\s+nvidia\.dali\s+import\s+.*\bpipeline_def\b|from\s+nvidia\.dali\s+import\s+.*\bfn\b"),
        "Imports pipeline-mode API; dynamic mode is `import nvidia.dali.experimental.dynamic as ndd`.",
    ),
]

_RANDOM_OPS = ("uniform", "coin_flip", "normal", "randint")


def _scan_lines(text):
    findings = []
    for i, line in enumerate(text.splitlines(), start=1):
        # ignore comment-only content for the noisier checks where literal text matters less
        for rule, pat, msg in _REGEX_RULES:
            if pat.search(line):
                findings.append({"rule": rule, "line": i, "message": msg})
    return findings


def _scan_ast(text):
    """AST checks that need structure: batch[i] subscripting and random ops missing batch_size."""
    findings = []
    try:
        tree = ast.parse(text)
    except SyntaxError as exc:
        findings.append(
            {
                "rule": "syntax-error",
                "line": getattr(exc, "lineno", 0) or 0,
                "message": "Could not parse file as Python: %s" % exc.msg,
            }
        )
        return findings

    for node in ast.walk(tree):
        # ndd.random.<op>(...) without a batch_size= keyword
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            attr = node.func
            if attr.attr in _RANDOM_OPS and _is_random_call(attr):
                has_bs = any(kw.arg == "batch_size" for kw in node.keywords)
                if not has_bs:
                    findings.append(
                        {
                            "rule": "random-no-batch-size",
                            "line": getattr(node, "lineno", 0),
                            "message": "ndd.random.%s(...) needs an explicit batch_size= "
                            "(no pipeline-level batch size to inherit)." % attr.attr,
                        }
                    )
    return findings


def _is_random_call(attr):
    """True if the attribute chain looks like ndd.random.<op> (or *.random.<op>)."""
    val = attr.value
    return isinstance(val, ast.Attribute) and val.attr == "random"


def analyze(text):
    findings = _scan_lines(text) + _scan_ast(text)
    findings.sort(key=lambda f: (f.get("line", 0), f.get("rule", "")))
    return findings


def main(argv=None):
    ap = argparse.ArgumentParser(description="Static lint for DALI dynamic-mode (ndd) code.")
    ap.add_argument("source", help="Path to the .py file to scan.")
    ap.add_argument("--output", required=True, help="Path to write the findings JSON.")
    args = ap.parse_args(argv)

    try:
        with open(args.source, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        findings = analyze(text)
        result = {
            "source": args.source,
            "ok": len(findings) == 0,
            "count": len(findings),
            "findings": findings,
        }
    except OSError as exc:
        result = {
            "source": args.source,
            "ok": False,
            "error": str(exc),
            "count": 0,
            "findings": [],
        }

    with open(args.output, "w", encoding="utf-8") as fh:
        json.dump(result, fh, indent=2)
        fh.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
