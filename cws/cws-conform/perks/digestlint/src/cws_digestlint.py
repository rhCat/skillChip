#!/usr/bin/env python3
"""cws_digestlint — prove every JSON-object hash routes through cwp.canonical, not ad-hoc json.dumps (P0-T04).

The digest-cutover criterion (F1 / P0-V03): outside infra/cwp, NO hash may be computed over `json.dumps`
output — every JSON-object digest must go through `cwp.canonical_bytes` (the one RFC-8785 JCS form the Go
anchor reproduces). This is an AST lint that flags a hashlib hash call (sha*/md5/blake2*/sha3*/new) whose
argument carries json.dumps output, in any of three shapes:
  (1) same expression — hashlib.sha256(json.dumps(...).encode())
  (2) data flow       — canon = json.dumps(...); hashlib.sha256(canon.encode())   (compiler.plan_sha)
  (3) helper          — def _canon(o): return json.dumps(o)...; hashlib.sha256(_canon(x))  (cws-observe)
Taint is SCOPED per function (with module globals) so an unrelated `key` assigned from a *hash* is not
conflated with a `key` fed to a hash elsewhere; and "carries dumps output" peels `.encode()` but stops at
a hash call, so `key = hashlib.sha256(json.dumps(...))` does NOT taint `key` (it holds the digest). It
deliberately does NOT flag mere file-level co-occurrence — raw-byte hashlib and unrelated json.dumps
coexist legitimately. That is why the naive file-grep criterion is unsatisfiable; this replaces it.

Reads from env: SCAN_ROOT (dir to scan), optional EXCLUDE (';'-separated path substrings skipped; default
"infra/cwp"), optional WHITELIST (';'-separated "relpath" or "relpath:line" exempt sites), RECORD_STORE.
Writes RECORD_STORE/digestlint.json + one JSON line. Exit 0 iff no non-whitelisted violation remains.
"""
from __future__ import annotations
import ast
import json
import os
import sys

HASH_FUNCS = {"sha1", "sha224", "sha256", "sha384", "sha512", "sha3_256", "sha3_512",
              "md5", "blake2b", "blake2s", "new"}
BOUNDARY = (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda, ast.ClassDef)


def _carries_dumps(node, dumps_funcs):
    """True if `node` EVALUATES to (a transform of) json.dumps output: a direct json.dumps(...) call, a
    call to a dumps-returning helper, or those peeled through chained .encode()/.attr — but NOT a hash
    call wrapping dumps (that evaluates to the digest, so its target is not tainted)."""
    while True:
        if isinstance(node, ast.Call):
            f = node.func
            if isinstance(f, ast.Attribute) and f.attr == "dumps":
                return True
            if isinstance(f, ast.Name) and f.id in dumps_funcs:
                return True
            if isinstance(f, ast.Attribute):              # peel x.encode()/x.format() -> x
                node = f.value
                continue
            return False
        if isinstance(node, ast.Attribute):
            node = node.value
            continue
        return False


def _is_hash_call(node):
    """True if `node` is a hashlib hash constructor call: hashlib.<sha*/md5/blake2*/new>(...)."""
    return isinstance(node.func, ast.Attribute) and node.func.attr in HASH_FUNCS


def _scope_nodes(scope):
    """Every node lexically in `scope` but NOT inside a nested function/lambda/class — one variable scope."""
    out, stack = [], list(ast.iter_child_nodes(scope))
    while stack:
        n = stack.pop()
        out.append(n)
        if not isinstance(n, BOUNDARY):
            stack.extend(ast.iter_child_nodes(n))
    return out


def scan_file(path):
    try:
        src = open(path, encoding="utf-8").read()
        tree = ast.parse(src, filename=path)
    except (SyntaxError, UnicodeDecodeError):
        return []
    lines = src.splitlines()

    funcs = [n for n in ast.walk(tree) if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))]
    dumps_funcs = {f.name for f in funcs
                   if any(isinstance(r, ast.Return) and r.value is not None and _carries_dumps(r.value, set())
                          for r in ast.walk(f))}

    def taint_of(nodes):
        t = set()
        for n in nodes:
            value = n.value if isinstance(n, (ast.Assign, ast.AnnAssign)) else None
            if value is not None and _carries_dumps(value, dumps_funcs):
                targets = n.targets if isinstance(n, ast.Assign) else [n.target]
                t.update(tt.id for tt in targets if isinstance(tt, ast.Name))
        return t

    def arg_carries(arg, tainted):
        """Does a hash-call argument carry dumps output — direct dumps, a dumps-helper call, or a tainted name?"""
        for d in ast.walk(arg):
            if isinstance(d, ast.Call) and isinstance(d.func, ast.Attribute) and d.func.attr == "dumps":
                return "expr"
            if isinstance(d, ast.Call) and isinstance(d.func, ast.Name) and d.func.id in dumps_funcs:
                return "helper"
            if isinstance(d, ast.Name) and d.id in tainted:
                return "var"
        return None

    module_nodes = _scope_nodes(tree)
    module_taint = taint_of(module_nodes)
    hits, seen = [], set()

    def process(nodes, tainted):
        for node in nodes:
            if isinstance(node, ast.Call) and _is_hash_call(node) and node.lineno not in seen:
                via = next((v for a in node.args if (v := arg_carries(a, tainted))), None)
                if via:
                    seen.add(node.lineno)
                    hits.append({"line": node.lineno, "snippet": lines[node.lineno - 1].strip()[:120], "via": via})

    process(module_nodes, module_taint)
    for f in funcs:
        nodes = _scope_nodes(f)
        process(nodes, module_taint | taint_of(nodes))
    return hits


def main() -> int:
    root = os.environ["SCAN_ROOT"].rstrip("/")
    exclude = [s.strip() for s in os.environ.get("EXCLUDE", "infra/cwp").split(";") if s.strip()]
    whitelist = {s.strip() for s in os.environ.get("WHITELIST", "").split(";") if s.strip()}
    store = os.environ["RECORD_STORE"].rstrip("/")
    out = os.path.join(store, "digestlint.json")
    os.makedirs(store, exist_ok=True)

    violations, whitelisted_hits, scanned = [], [], 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != "__pycache__" and not d.startswith(".")]
        for fn in sorted(filenames):
            if not fn.endswith(".py"):
                continue
            ap = os.path.join(dirpath, fn)
            rel = os.path.relpath(ap, root)
            if any(ex in rel for ex in exclude):
                continue
            scanned += 1
            for hit in scan_file(ap):
                site = f"{rel}:{hit['line']}"
                if site in whitelist or rel in whitelist:
                    whitelisted_hits.append(site)
                else:
                    violations.append({"site": site, "via": hit["via"], "snippet": hit["snippet"]})

    status = "ok" if not violations else "fail"
    report = {"scan_root": root, "scanned": scanned, "exclude": exclude,
              "whitelist": sorted(whitelist), "whitelisted_hits": sorted(whitelisted_hits),
              "violations": violations, "status": status}
    json.dump(report, open(out, "w"), indent=2)
    print(json.dumps({"tool": "cws_digestlint", "status": status, "scanned": scanned,
                      "violations": len(violations), "whitelisted": len(whitelisted_hits), "report": out}))
    return 0 if status == "ok" else 1


if __name__ == "__main__":
    sys.exit(main())
