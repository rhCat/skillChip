#!/usr/bin/env python3
"""
TDC Data Loading and Splitting (vendored core)

Loads a Therapeutics Data Commons dataset and produces a train/valid/test split
with the requested strategy, then writes a JSON report (split sizes + a small
sample) to --out. Adapted/condensed from the K-Dense pytdc skill
scripts/load_and_split_data.py into a single deterministic CLI operation.

The heavy `tdc` import is performed lazily inside run() so that this core can be
invoked offline (it then emits a structured "skipped" report instead of crashing).

Usage:
    python tdc_load_split_core.py --problem single_pred --task ADME \
        --dataset Caco2_Wang --method scaffold --seed 42 --out split.json
"""
import argparse
import json
import sys


def run(problem, task, dataset, method, seed, frac, out_path):
    report = {
        "tool": "tdc_load_split",
        "problem": problem,
        "task": task,
        "dataset": dataset,
        "method": method,
        "seed": seed,
        "frac": frac,
    }
    try:
        import importlib

        mod = importlib.import_module("tdc.%s" % problem)
        Task = getattr(mod, task)
    except Exception as e:  # tdc absent / unknown task -> graceful skip
        report["status"] = "skipped"
        report["reason"] = "tdc unavailable or unknown problem/task: %s" % e
        with open(out_path, "w") as fh:
            json.dump(report, fh, indent=2)
        return 0

    try:
        data = Task(name=dataset)
        split = data.get_split(method=method, seed=seed, frac=frac)
        sizes = {k: int(len(v)) for k, v in split.items()}
        sample = split["train"].head(3).to_dict(orient="records")
        report["status"] = "ok"
        report["sizes"] = sizes
        report["columns"] = list(split["train"].columns)
        report["sample_train"] = sample
    except Exception as e:
        report["status"] = "error"
        report["reason"] = str(e)

    with open(out_path, "w") as fh:
        json.dump(report, fh, indent=2)
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description="Load + split a TDC dataset.")
    p.add_argument("--problem", required=True,
                   help="single_pred | multi_pred | generation")
    p.add_argument("--task", required=True,
                   help="Task class, e.g. ADME, Tox, DTI, DDI, MolGen")
    p.add_argument("--dataset", required=True,
                   help="Dataset name, e.g. Caco2_Wang, BindingDB_Kd")
    p.add_argument("--method", default="scaffold",
                   help="random | scaffold | cold_drug | cold_target | temporal")
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--frac", default="0.7,0.1,0.2",
                   help="train,valid,test fractions")
    p.add_argument("--out", required=True, help="output JSON path")
    a = p.parse_args(argv)
    frac = [float(x) for x in a.frac.split(",")]
    return run(a.problem, a.task, a.dataset, a.method, a.seed, frac, a.out)


if __name__ == "__main__":
    sys.exit(main())
