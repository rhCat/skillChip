#!/usr/bin/env python3
# cli_simulate_power — thin CLI over the vendored simulate_power harness.
# Runs Monte Carlo power for one of the bundled worked designs (the intended
# starting point a user copies and adapts), at a fixed n. Writes a JSON result
# including the Wilson Monte-Carlo confidence interval.
# Vendored core: simulate_power.py (unchanged).
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
    design = os.environ.get("DESIGN", "two_group")
    n = _i("N", 64)
    n_sims = _i("N_SIMS", 1000)
    alpha = _f("ALPHA", 0.05)
    seed = _i("SEED", 0)
    effect = _f("EFFECT", 0.5)

    from simulate_power import (
        simulate_power,
        example_two_group_difference,
        example_logistic_regression,
        example_cluster_randomized,
        example_linear_mixed_repeated,
    )

    if design == "two_group":
        gen = example_two_group_difference(effect=effect, alpha=alpha)
    elif design == "logistic":
        gen = example_logistic_regression(beta=effect, alpha=alpha)
    elif design == "cluster_randomized":
        gen = example_cluster_randomized(effect=effect, alpha=alpha)
    elif design == "linear_mixed":
        gen = example_linear_mixed_repeated(effect=effect, alpha=alpha)
    else:
        raise ValueError(f"unknown design '{design}'")

    est = simulate_power(gen, n=n, n_sims=n_sims, alpha=alpha, seed=seed)
    result = {
        "tool": "cli_simulate_power",
        "operation": "simulate_power",
        "design": design,
        "n": n,
        "n_sims": n_sims,
        "alpha": alpha,
        "seed": seed,
        "effect": effect,
        "power": est.power,
        "ci_low": est.ci_low,
        "ci_high": est.ci_high,
    }
    with open(out, "w") as fh:
        json.dump(result, fh, indent=2, default=str)


if __name__ == "__main__":
    main()
