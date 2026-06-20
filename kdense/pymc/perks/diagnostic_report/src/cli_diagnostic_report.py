#!/usr/bin/env python3
"""
CLI wrapper around the vendored model_diagnostics.create_diagnostic_report().

Reads a saved PyMC/ArviZ InferenceData netCDF file and renders a full diagnostic
report — trace / rank / autocorrelation / energy / ESS plots plus a summary CSV —
into an output directory, then writes a JSON manifest of what was produced.

Env -> args:
    IDATA      : path to an InferenceData .nc file       (required)
    OUT        : path to the JSON manifest to write        (required)
    REPORT_DIR : directory for the rendered plots + CSV    (required)
    VAR_NAMES  : optional comma-separated variable names

Requires arviz + matplotlib (and the netCDF backend) for real output.
"""
import json
import os
import sys

import matplotlib  # noqa: E402
matplotlib.use("Agg")  # headless: never open a window

import model_diagnostics  # vendored, unchanged


def main():
    idata_path = os.environ.get("IDATA")
    out_path = os.environ.get("OUT")
    report_dir = os.environ.get("REPORT_DIR")
    if not idata_path or not out_path or not report_dir:
        print("IDATA, OUT and REPORT_DIR must be set", file=sys.stderr)
        return 2

    var_names_env = os.environ.get("VAR_NAMES", "").strip()
    var_names = [v.strip() for v in var_names_env.split(",") if v.strip()] or None

    import arviz as az

    idata = az.from_netcdf(idata_path)
    os.makedirs(report_dir, exist_ok=True)
    results = model_diagnostics.create_diagnostic_report(
        idata, var_names=var_names, output_dir=report_dir, show=False
    )

    artifacts = sorted(os.listdir(report_dir)) if os.path.isdir(report_dir) else []
    payload = {
        "tool": "diagnostic_report",
        "idata": idata_path,
        "report_dir": report_dir,
        "artifacts": artifacts,
        "has_issues": bool(results.get("has_issues", False)),
        "issues": list(results.get("issues", [])),
    }
    with open(out_path, "w") as fh:
        json.dump(payload, fh, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main())
