#!/usr/bin/env python3
# cli_mde — thin CLI over the vendored power.mde().
# Reads params from environment, solves for the minimum detectable effect at a
# fixed n, writes a JSON result. Vendored core: power.py (unchanged).
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def _f(name, default=None):
    v = os.environ.get(name, "")
    return float(v) if v not in ("", None) else default


def _i(name, default=None):
    v = os.environ.get(name, "")
    return int(float(v)) if v not in ("", None) else default


def main():
    out = os.environ["OUT"]
    test = os.environ.get("TEST", "t_ind")
    alpha = _f("ALPHA", 0.05)
    power_target = _f("POWER", 0.80)
    alternative = os.environ.get("ALTERNATIVE", "two-sided")
    nobs1 = _f("NOBS1")
    nobs = _f("NOBS")

    kw = {}
    for env_name, kw_name, conv in (
        ("RATIO", "ratio", _f),
        ("K_GROUPS", "k_groups", _i),
        ("PROP1", "prop1", _f),
        ("PROP2", "prop2", _f),
        ("PROP0", "prop0", _f),
        ("DOF", "dof", _i),
        ("DF_NUM", "df_num", _i),
        ("K_TOTAL", "k_total", _i),
    ):
        val = conv(env_name)
        if val is not None:
            kw[kw_name] = val

    from power import mde

    effect = mde(test=test, nobs1=nobs1, nobs=nobs, alpha=alpha,
                 power=power_target, alternative=alternative, **kw)
    result = {
        "tool": "cli_mde",
        "operation": "mde",
        "test": test,
        "alpha": alpha,
        "power": power_target,
        "alternative": alternative,
        "nobs1": nobs1,
        "nobs": nobs,
        "params": kw,
        "min_detectable_effect": effect,
    }
    with open(out, "w") as fh:
        json.dump(result, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
