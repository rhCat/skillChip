#!/usr/bin/env python3
"""
TDC Benchmark Group Evaluation (vendored core)

Runs a TDC benchmark group's evaluate protocol (the required 5-seed protocol)
over a predictions payload and writes the per-dataset mean +/- std to --out.
Condensed from the K-Dense pytdc skill scripts/benchmark_evaluation.py into a
single deterministic CLI operation.

The predictions payload is a JSON object keyed by dataset name, each mapping
seed -> list of predictions, e.g.:
    {"Caco2_Wang": {"1": [...], "2": [...], "3": [...], "4": [...], "5": [...]}}

The `tdc` import is lazy; offline the core emits a structured "skipped" report.

Usage:
    python tdc_benchmark_core.py --group admet_group --pred preds.json \
        --path data/ --out bench.json
"""
import argparse
import json
import sys


def run(group_name, pred_path, data_path, out_path):
    report = {"tool": "tdc_benchmark", "group": group_name}
    try:
        with open(pred_path) as fh:
            payload = json.load(fh)
        # normalize seed keys to ints
        predictions = {
            ds: {int(seed): vals for seed, vals in seeds.items()}
            for ds, seeds in payload.items()
        }
        report["datasets"] = list(predictions.keys())
    except Exception as e:
        report["status"] = "error"
        report["reason"] = "could not read predictions: %s" % e
        with open(out_path, "w") as fh:
            json.dump(report, fh, indent=2)
        return 0

    try:
        import importlib

        bg = importlib.import_module("tdc.benchmark_group")
        group_ctor = getattr(bg, group_name)
    except Exception as e:
        report["status"] = "skipped"
        report["reason"] = "tdc benchmark_group unavailable or unknown group: %s" % e
        with open(out_path, "w") as fh:
            json.dump(report, fh, indent=2)
        return 0

    try:
        group = group_ctor(path=data_path)
        results = group.evaluate(predictions)
        # results: {dataset: [mean, std]}
        report["status"] = "ok"
        report["results"] = {
            ds: {"mean": float(v[0]), "std": float(v[1])}
            for ds, v in results.items()
        }
    except Exception as e:
        report["status"] = "error"
        report["reason"] = str(e)

    with open(out_path, "w") as fh:
        json.dump(report, fh, indent=2)
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description="Run a TDC benchmark group evaluation.")
    p.add_argument("--group", required=True,
                   help="benchmark group ctor, e.g. admet_group")
    p.add_argument("--pred", required=True,
                   help="JSON file: {dataset: {seed: [preds]}}")
    p.add_argument("--path", default="data/",
                   help="local cache dir for the benchmark group")
    p.add_argument("--out", required=True, help="output JSON path")
    a = p.parse_args(argv)
    return run(a.group, a.pred, a.path, a.out)


if __name__ == "__main__":
    sys.exit(main())
