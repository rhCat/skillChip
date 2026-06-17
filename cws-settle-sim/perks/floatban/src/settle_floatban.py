#!/usr/bin/env python3
"""settle_floatban — Money type + float-ban validator (P6-T01). Asserts the Money type rounds HALF_EVEN at
scale 4, refuses binary floats, and splits sum to the total exactly; AND that the float-ban AST lint finds
ZERO float intrusions in infra/settle (firing on a seed proves the 0 is real). Writes floatban.json; exits 0
iff both hold."""
import json
import os
import sys

_root = os.environ.get("CYBERWARE_ROOT")
if not _root:
    _d = os.path.dirname(os.path.abspath(__file__))
    while _d != os.path.dirname(_d) and not os.path.isdir(os.path.join(_d, "infra", "settle")):
        _d = os.path.dirname(_d)
    _root = _d
sys.path.insert(0, _root)

from infra.settle import money  # noqa: E402


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)
    m = money.money_selftest()
    fb = money.float_ban_selftest()
    r = {"money": m, "float_ban": fb, "ok": m["ok"] and fb["ok"]}
    with open(os.path.join(store, "floatban.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "settle_floatban", "ok": r["ok"],
                      "settle_float_occurrences": fb["settle_float_occurrences"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
