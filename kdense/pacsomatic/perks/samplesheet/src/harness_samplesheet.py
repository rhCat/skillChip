#!/usr/bin/env python3
"""Thin harness: build the pacsomatic samplesheet CSV by calling the UNCHANGED
vendored run_pacsomatic.py:build_samplesheet. Reads inputs from env, writes
${RECORD_STORE}/samplesheet.csv. No execution, no nextflow/conda required."""

import argparse
import os
import sys

# vendored core sits next to this harness; import it unchanged
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_pacsomatic as core  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--patient-id", required=True)
    p.add_argument("--tumor-sample-id", required=True)
    p.add_argument("--normal-sample-id", required=True)
    p.add_argument("--tumor-bam", required=True)
    p.add_argument("--normal-bam", required=True)
    p.add_argument("--tumor-pbi", default="")
    p.add_argument("--normal-pbi", default="")
    p.add_argument("--out", required=True)
    args = p.parse_args()

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    core.build_samplesheet(args, args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
