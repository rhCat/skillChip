#!/usr/bin/env python3
"""llm_payment_gate — P6-T09 validator for the llm/* schema-validation payment gate.

Proves two things and writes them to gate.json (exit 0 iff every boolean holds):
  (a) the settlement gate is sound — infra.settle.intelligence.intelligence_selftest: a schema-PASS pays the
      publisher their work share; a schema-FAIL pays the publisher ZERO and refunds the initiator the work
      share, yet STILL reimburses the provider passthrough and pays govd the fee; the penalty policy splits
      exactly; every posting set is balanced + globally zero-sum; settlement is idempotent per quote_sha;
  (b) THIS skill's OWN declared output contract (model.json -> io.output_contract) actually DISCRIMINATES —
      the declared `pass` sample is work, the declared `fail` sample is refused. A vacuous contract would not.
"""
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

from infra.settle import intelligence  # noqa: E402


def _find_model():
    """Walk up from this porter to the skill root (the dir holding model.json alongside SKILL.md)."""
    d = os.path.dirname(os.path.abspath(__file__))
    while d != os.path.dirname(d):
        mp = os.path.join(d, "model.json")
        if os.path.isfile(mp) and os.path.isfile(os.path.join(d, "SKILL.md")):
            return mp
        d = os.path.dirname(d)
    raise FileNotFoundError("model.json not found above the porter")


def main():
    store = os.environ["RECORD_STORE"].rstrip("/")
    os.makedirs(store, exist_ok=True)

    model = json.load(open(_find_model()))
    contract = model["io"]["output_contract"]
    samples = model["samples"]
    # the declared contract must DISCRIMINATE: the declared pass-sample is work, the fail-sample is not
    declared = (intelligence.validate_output(samples["pass"], contract)["pass"] is True
                and intelligence.validate_output(samples["fail"], contract)["pass"] is False)

    r = intelligence.intelligence_selftest()
    r["declared_contract_discriminates"] = bool(declared)
    r["ok"] = all(v for v in r.values() if isinstance(v, bool))

    with open(os.path.join(store, "gate.json"), "w") as f:
        json.dump(r, f, indent=2)
    print(json.dumps({"tool": "llm_payment_gate", "ok": r["ok"]}))
    sys.exit(0 if r["ok"] else 1)


if __name__ == "__main__":
    main()
