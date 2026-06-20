#!/usr/bin/env python3
"""Thin harness: write the generated Nextflow params YAML by calling the UNCHANGED
vendored run_pacsomatic.py:build_generated_params_content. Reads inputs from env,
writes the params YAML to --out. No execution, no nextflow/conda required."""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_pacsomatic as core  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True, help="samplesheet path written into params")
    p.add_argument("--outdir", required=True)
    p.add_argument("--fasta", default="")
    p.add_argument("--genome", default="")
    p.add_argument("--out", required=True, help="params YAML output path")
    args = p.parse_args()

    if not args.fasta and not args.genome:
        raise SystemExit("[ERROR] one of --fasta or --genome is required")

    content = core.build_generated_params_content(args, args.input)
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as handle:
        handle.write(content)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
