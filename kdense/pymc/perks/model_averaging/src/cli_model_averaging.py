#!/usr/bin/env python3
"""
CLI wrapper around the vendored model_comparison.model_averaging().

Loads two or more saved PyMC/ArviZ InferenceData netCDF files, computes pseudo-BMA
model weights from an information criterion, and forms a weighted average of their
posterior-predictive draws for a named variable. Writes the weights plus summary
statistics of the averaged prediction as JSON, and the full averaged array as .npy.

Env -> args:
    MODELS_DIR : directory containing *.nc files                  (one of MODELS_DIR / MODELS)
    MODELS     : comma-separated list of name=path.nc (or path.nc) (one of MODELS_DIR / MODELS)
    OUT        : path to the JSON result to write                (required)
    VAR_NAME   : predicted variable name (default 'y_obs')
    IC         : information criterion for weights, 'loo' (default) or 'waic'

Requires arviz + numpy (+ pymc) importable for real output.
"""
import glob
import json
import os
import sys

import numpy as np

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
    var_name = os.environ.get("VAR_NAME", "y_obs").strip() or "y_obs"
    ic = os.environ.get("IC", "loo").strip() or "loo"

    import arviz as az

    models = _resolve_models(az)
    averaged, weights = model_comparison.model_averaging(
        models, var_name=var_name, ic=ic
    )
    averaged = np.asarray(averaged)
    weights = np.asarray(weights)

    npy_path = os.path.splitext(out_path)[0] + "_predictions.npy"
    np.save(npy_path, averaged)

    payload = {
        "tool": "model_averaging",
        "var_name": var_name,
        "ic": ic,
        "models": list(models.keys()),
        "weights": [float(w) for w in weights.tolist()],
        "averaged_shape": list(averaged.shape),
        "averaged_mean": float(averaged.mean()) if averaged.size else None,
        "predictions_npy": npy_path,
    }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2, default=str)
    return 0


if __name__ == "__main__":
    sys.exit(main())
