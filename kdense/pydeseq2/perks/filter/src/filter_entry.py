#!/usr/bin/env python3
"""
filter_entry — standalone gene/sample filter for an RNA-seq count matrix.

This stage mirrors the `load_and_validate_data` + `filter_data` functions of the
vendored run_deseq2_analysis.py (kept alongside for provenance) but is implemented
self-contained in pure pandas so it runs fully offline WITHOUT importing pydeseq2
(the vendored core guards its top-level pydeseq2 import and exits if absent).

Behaviour, faithful to the source:
  - load counts CSV (genes x samples), transpose to samples x genes unless NO_TRANSPOSE
  - intersect counts/metadata sample indices if they don't match
  - reject negative counts
  - drop genes whose total counts < MIN_COUNTS
  - drop samples with missing CONDITION_COL (if provided)
  - write the filtered samples x genes matrix to OUT

Env:
    COUNTS         path to counts CSV (genes x samples by default; transposed)
    METADATA       path to metadata CSV (samples x variables)
    MIN_COUNTS     minimum total counts to keep a gene (default 10)
    CONDITION_COL  metadata column whose NaNs drop a sample (optional)
    NO_TRANSPOSE   if "1"/"true", do not transpose the count matrix
    OUT            output CSV path for the filtered counts (required)
"""

import os
import sys

import pandas as pd


def _as_bool(value):
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def main():
    counts_path = os.environ["COUNTS"]
    metadata_path = os.environ["METADATA"]
    out_path = os.environ["OUT"]
    min_counts = int(os.environ.get("MIN_COUNTS", "10"))
    condition_col = os.environ.get("CONDITION_COL") or None
    transpose = not _as_bool(os.environ.get("NO_TRANSPOSE", ""))

    counts_df = pd.read_csv(counts_path, index_col=0)
    if transpose:
        counts_df = counts_df.T
    metadata = pd.read_csv(metadata_path, index_col=0)

    if not all(counts_df.index == metadata.index):
        common = counts_df.index.intersection(metadata.index)
        counts_df = counts_df.loc[common]
        metadata = metadata.loc[common]

    if (counts_df < 0).any().any():
        raise ValueError("Count matrix contains negative values")

    genes_to_keep = counts_df.columns[counts_df.sum(axis=0) >= min_counts]
    counts_df = counts_df[genes_to_keep]

    if condition_col and condition_col in metadata.columns:
        samples_to_keep = ~metadata[condition_col].isna()
        counts_df = counts_df.loc[samples_to_keep]
        metadata = metadata.loc[samples_to_keep]

    counts_df.to_csv(out_path)
    print(
        f"{{\"tool\":\"filter_counts\",\"status\":\"ok\","
        f"\"samples\":{counts_df.shape[0]},\"genes\":{counts_df.shape[1]},"
        f"\"out\":\"{out_path}\"}}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
