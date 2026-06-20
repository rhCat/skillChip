#!/usr/bin/env python3
"""
TDC Model Evaluation (vendored core)

Scores predictions against ground truth with a standardized TDC metric
(ROC-AUC, PR-AUC, F1, Accuracy, RMSE, MAE, R2, Spearman, Pearson, ...).
Reads a JSON payload {"y_true": [...], "y_pred": [...]} and writes a JSON
report {metric, score} to --out. Condensed from the K-Dense pytdc skill
scripts/load_and_split_data.py (evaluation_example).

The `tdc` import is lazy; offline the core emits a structured "skipped" report
rather than crashing.

Usage:
    python tdc_evaluate_core.py --metric MAE --pred preds.json --out eval.json
"""
import argparse
import json
import sys


def run(metric, pred_path, out_path):
    report = {"tool": "tdc_evaluate", "metric": metric}
    try:
        with open(pred_path) as fh:
            payload = json.load(fh)
        y_true = payload["y_true"]
        y_pred = payload["y_pred"]
        report["n"] = len(y_true)
    except Exception as e:
        report["status"] = "error"
        report["reason"] = "could not read predictions: %s" % e
        with open(out_path, "w") as fh:
            json.dump(report, fh, indent=2)
        return 0

    try:
        from tdc import Evaluator
    except Exception as e:
        report["status"] = "skipped"
        report["reason"] = "tdc unavailable: %s" % e
        with open(out_path, "w") as fh:
            json.dump(report, fh, indent=2)
        return 0

    try:
        evaluator = Evaluator(name=metric)
        score = evaluator(y_true, y_pred)
        report["status"] = "ok"
        report["score"] = float(score)
    except Exception as e:
        report["status"] = "error"
        report["reason"] = str(e)

    with open(out_path, "w") as fh:
        json.dump(report, fh, indent=2)
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description="Score predictions with a TDC metric.")
    p.add_argument("--metric", required=True,
                   help="ROC-AUC | PR-AUC | F1 | Accuracy | RMSE | MAE | R2 | Spearman | Pearson | ...")
    p.add_argument("--pred", required=True,
                   help="JSON file: {\"y_true\": [...], \"y_pred\": [...]}")
    p.add_argument("--out", required=True, help="output JSON path")
    a = p.parse_args(argv)
    return run(a.metric, a.pred, a.out)


if __name__ == "__main__":
    sys.exit(main())
