#!/usr/bin/env python3
# cli_power_curve — thin CLI over the vendored power.power_curve().
# Reads params from environment, computes power vs. sample size, saves a PNG
# figure under RECORD_STORE, and writes the (n, power) arrays as JSON to OUT.
# Vendored core: power.py (unchanged). matplotlib runs headless (Agg).
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import matplotlib  # noqa: E402
matplotlib.use("Agg")


def _f(name, default=None):
    v = os.environ.get(name, "")
    return float(v) if v not in ("", None) else default


def _i(name, default=None):
    v = os.environ.get(name, "")
    return int(float(v)) if v not in ("", None) else default


def main():
    out = os.environ["OUT"]
    store = os.environ["RECORD_STORE"].rstrip("/")
    test = os.environ.get("TEST", "t_ind")
    alpha = _f("ALPHA", 0.05)
    power_target = _f("POWER", 0.80)
    alternative = os.environ.get("ALTERNATIVE", "two-sided")
    effect_size = _f("EFFECT_SIZE")

    n_start = _i("N_START", 5)
    n_stop = _i("N_STOP", 205)
    n_step = _i("N_STEP", 5)

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

    png = os.path.join(store, "power_curve.png")

    from power import power_curve

    ns, pwr = power_curve(
        test=test, effect_size=effect_size,
        n_range=range(n_start, n_stop, n_step),
        alpha=alpha, power_target=power_target,
        alternative=alternative, save=png, show=False, **kw,
    )
    result = {
        "tool": "cli_power_curve",
        "operation": "power_curve",
        "test": test,
        "alpha": alpha,
        "power_target": power_target,
        "alternative": alternative,
        "effect_size": effect_size,
        "params": kw,
        "figure": png,
        "n": [float(x) for x in ns],
        "power": [float(x) for x in pwr],
    }
    with open(out, "w") as fh:
        json.dump(result, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
