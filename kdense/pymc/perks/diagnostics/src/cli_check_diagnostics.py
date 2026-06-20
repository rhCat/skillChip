#!/usr/bin/env python3
"""
CLI wrapper around the vendored model_diagnostics.check_diagnostics().

Reads a saved PyMC/ArviZ InferenceData netCDF file (idata.to_netcdf), runs the
quick MCMC diagnostic check (R-hat, ESS, divergences, tree depth) and writes a
machine-readable JSON summary.

Env -> args:
    IDATA   : path to an InferenceData .nc file  (required)
    OUT     : path to the JSON summary to write   (required)
    VAR_NAMES : optional comma-separated variable names to restrict the check

Requires arviz (and the netCDF backend) to be importable for real output.
"""
import json
import os
import sys

import model_diagnostics  # vendored, unchanged


def _to_jsonable(obj):
    try:
        import numpy as np
        if isinstance(obj, (np.integer,)):
            return int(obj)
        if isinstance(obj, (np.floating,)):
            return float(obj)
        if isinstance(obj, (np.bool_,)):
            return bool(obj)
    except Exception:
        pass
    return str(obj)


def main():
    idata_path = os.environ.get("IDATA")
    out_path = os.environ.get("OUT")
    if not idata_path or not out_path:
        print("IDATA and OUT must be set", file=sys.stderr)
        return 2

    var_names_env = os.environ.get("VAR_NAMES", "").strip()
    var_names = [v.strip() for v in var_names_env.split(",") if v.strip()] or None

    import arviz as az

    idata = az.from_netcdf(idata_path)
    results = model_diagnostics.check_diagnostics(idata, var_names=var_names)

    payload = {
        "tool": "check_diagnostics",
        "idata": idata_path,
        "has_issues": bool(results.get("has_issues", False)),
        "issues": list(results.get("issues", [])),
        "n_divergences": int(results.get("n_divergences", 0) or 0),
    }
    summary = results.get("summary")
    if summary is not None:
        try:
            payload["summary"] = json.loads(summary.to_json(orient="index"))
        except Exception:
            payload["summary_repr"] = str(summary)

    with open(out_path, "w") as fh:
        json.dump(payload, fh, default=_to_jsonable, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
