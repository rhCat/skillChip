#!/usr/bin/env python3
"""
CLI wrapper around the vendored model_comparison.compare_models().

Loads two or more saved PyMC/ArviZ InferenceData netCDF files (each must carry a
log_likelihood group) and ranks them by an information criterion (LOO or WAIC),
writing the comparison table as JSON.

Env -> args:
    MODELS_DIR : directory containing *.nc files                  (one of MODELS_DIR / MODELS)
    MODELS     : comma-separated list of name=path.nc (or path.nc) (one of MODELS_DIR / MODELS)
    OUT        : path to the JSON comparison to write             (required)
    IC         : information criterion, 'loo' (default) or 'waic'

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
    ic = os.environ.get("IC", "loo").strip() or "loo"

    import arviz as az

    models = _resolve_models(az)
    comparison = model_comparison.compare_models(models, ic=ic, verbose=False)

    payload = {
        "tool": "compare_models",
        "ic": ic,
        "models": list(models.keys()),
        "best": str(comparison.index[0]) if len(comparison) else None,
        "ranking": json.loads(comparison.to_json(orient="index")),
    }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)
    return 0


if __name__ == "__main__":
    sys.exit(main())
