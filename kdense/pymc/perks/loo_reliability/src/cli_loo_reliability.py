#!/usr/bin/env python3
"""
CLI wrapper around the vendored model_comparison.check_loo_reliability().

Loads one or more saved PyMC/ArviZ InferenceData netCDF files and reports LOO-CV
reliability via Pareto-k diagnostics (how many points exceed the threshold, the
maximum k), writing the result as JSON.

Env -> args:
    MODELS_DIR : directory containing *.nc files                  (one of MODELS_DIR / MODELS)
    MODELS     : comma-separated list of name=path.nc (or path.nc) (one of MODELS_DIR / MODELS)
    OUT        : path to the JSON result to write                (required)
    THRESHOLD  : Pareto-k flag threshold (default 0.7)

Requires arviz (+ pymc) importable for real output.
"""
import glob
import json
import os
import sys

import model_comparison  # vendored, unchanged


def _resolve_models(az):
    models = {}
    models_env = os.environ.get("MODELS", "").strip()
    models_dir = os.environ.get("MODELS_DIR", "").strip()
    if models_env:
        for token in [t.strip() for t in models_env.split(",") if t.strip()]:
            if "=" in token:
                name, path = token.split("=", 1)
            else:
                name, path = os.path.splitext(os.path.basename(token))[0], token
            models[name.strip()] = az.from_netcdf(path.strip())
    elif models_dir:
        for path in sorted(glob.glob(os.path.join(models_dir, "*.nc"))):
            name = os.path.splitext(os.path.basename(path))[0]
            models[name] = az.from_netcdf(path)
    return models


def main():
    out_path = os.environ.get("OUT")
    if not out_path:
        print("OUT must be set", file=sys.stderr)
        return 2
    threshold = float(os.environ.get("THRESHOLD", "0.7") or "0.7")

    import arviz as az

    models = _resolve_models(az)
    results = model_comparison.check_loo_reliability(models, threshold=threshold, verbose=False)

    summary = {
        "tool": "loo_reliability",
        "threshold": threshold,
        "models": {},
    }
    for name, r in results.items():
        summary["models"][name] = {
            "n_high": int(r.get("n_high", 0)),
            "n_very_high": int(r.get("n_very_high", 0)),
            "max_k": float(r.get("max_k", float("nan"))),
        }
    with open(out_path, "w") as fh:
        json.dump(summary, fh, indent=2, default=str)
    return 0


if __name__ == "__main__":
    sys.exit(main())
