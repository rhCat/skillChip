#!/usr/bin/env python3
"""
TDC Molecular Oracle Scoring (vendored core)

Scores a list of SMILES with a TDC molecular oracle (QED, SA, LogP, GSK3B,
DRD2, JNK3, ...) for molecular optimization, and writes per-SMILES scores plus
summary statistics to --out. Condensed from the K-Dense pytdc skill
scripts/molecular_generation.py into a single deterministic CLI operation.

The SMILES are read one-per-line from --smiles. The `tdc` import is lazy;
offline the core emits a structured "skipped" report rather than crashing.

Usage:
    python tdc_oracle_score_core.py --oracle QED --smiles mols.smi --out scores.json
"""
import argparse
import json
import sys


def run(oracle_name, smiles_path, out_path):
    report = {"tool": "tdc_oracle_score", "oracle": oracle_name}
    try:
        with open(smiles_path) as fh:
            smiles = [line.strip() for line in fh if line.strip()]
        report["n"] = len(smiles)
    except Exception as e:
        report["status"] = "error"
        report["reason"] = "could not read SMILES: %s" % e
        with open(out_path, "w") as fh:
            json.dump(report, fh, indent=2)
        return 0

    try:
        from tdc import Oracle
    except Exception as e:
        report["status"] = "skipped"
        report["reason"] = "tdc unavailable: %s" % e
        with open(out_path, "w") as fh:
            json.dump(report, fh, indent=2)
        return 0

    try:
        oracle = Oracle(name=oracle_name)
        scores = oracle(smiles)
        if not isinstance(scores, list):
            scores = [scores]
        scores = [float(s) for s in scores]
        report["status"] = "ok"
        report["scores"] = dict(zip(smiles, scores))
        if scores:
            n = len(scores)
            mean = sum(scores) / n
            report["summary"] = {
                "mean": mean,
                "min": min(scores),
                "max": max(scores),
            }
    except Exception as e:
        report["status"] = "error"
        report["reason"] = str(e)

    with open(out_path, "w") as fh:
        json.dump(report, fh, indent=2)
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description="Score SMILES with a TDC oracle.")
    p.add_argument("--oracle", required=True,
                   help="oracle name, e.g. QED, SA, LogP, GSK3B, DRD2, JNK3")
    p.add_argument("--smiles", required=True,
                   help="text file with one SMILES per line")
    p.add_argument("--out", required=True, help="output JSON path")
    a = p.parse_args(argv)
    return run(a.oracle, a.smiles, a.out)


if __name__ == "__main__":
    sys.exit(main())
