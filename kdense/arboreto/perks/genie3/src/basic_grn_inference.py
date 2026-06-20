#!/usr/bin/env python3
"""
Basic GRN inference using Arboreto (vendored, algorithm-parameterized).

This script demonstrates the standard workflow for inferring gene regulatory
networks from expression data using GRNBoost2 (gradient boosting) or GENIE3
(Random Forest). Vendored UNCHANGED in structure from the K-Dense `arboreto`
skill (scripts/basic_grn_inference.py); the only addition is an `--algo` flag so
the same core backs both governed perks.

Usage:
    python basic_grn_inference.py <expression_file> <output_file> [--algo grnboost2|genie3] [--tf-file TF_FILE] [--seed SEED] [--limit LIMIT]

Arguments:
    expression_file: Path to expression matrix (TSV format, genes as columns)
    output_file: Path for output network (TSV format)
    --algo: Inference algorithm — grnboost2 (default) or genie3
    --tf-file: Optional path to transcription factors file (one per line)
    --seed: Random seed for reproducibility (default: 777)
    --limit: Return only the top N regulatory links (optional)
"""

import argparse
import pandas as pd
from arboreto.algo import grnboost2, genie3
from arboreto.utils import load_tf_names


ALGORITHMS = {'grnboost2': grnboost2, 'genie3': genie3}


def run_grn_inference(expression_file, output_file, algo='grnboost2', tf_file=None, seed=777, limit=None):
    """
    Run GRN inference using the selected algorithm.

    Args:
        expression_file: Path to expression matrix TSV file
        output_file: Path for output network file
        algo: 'grnboost2' (gradient boosting) or 'genie3' (Random Forest)
        tf_file: Optional path to TF names file
        seed: Random seed for reproducibility
        limit: Optional cap on number of regulatory links returned
    """
    infer = ALGORITHMS[algo]

    print(f"Loading expression data from {expression_file}...")
    expression_data = pd.read_csv(expression_file, sep='\t')

    print(f"Expression matrix shape: {expression_data.shape}")
    print(f"Number of genes: {expression_data.shape[1]}")
    print(f"Number of observations: {expression_data.shape[0]}")

    # Load TF names if provided
    tf_names = 'all'
    if tf_file:
        print(f"Loading transcription factors from {tf_file}...")
        tf_names = load_tf_names(tf_file)
        print(f"Number of TFs: {len(tf_names)}")

    # Run GRN inference
    print(f"Running {algo} with seed={seed}...")
    network = infer(
        expression_data=expression_data,
        tf_names=tf_names,
        seed=seed,
        limit=limit,
        verbose=True
    )

    # Save results
    print(f"Saving network to {output_file}...")
    network.to_csv(output_file, sep='\t', index=False, header=False)

    print(f"Done! Network contains {len(network)} regulatory links.")
    print(f"\nTop 10 regulatory links:")
    print(network.head(10).to_string(index=False))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Infer gene regulatory network using GRNBoost2 or GENIE3'
    )
    parser.add_argument(
        'expression_file',
        help='Path to expression matrix (TSV format, genes as columns)'
    )
    parser.add_argument(
        'output_file',
        help='Path for output network (TSV format)'
    )
    parser.add_argument(
        '--algo',
        help='Inference algorithm (default: grnboost2)',
        choices=['grnboost2', 'genie3'],
        default='grnboost2'
    )
    parser.add_argument(
        '--tf-file',
        help='Path to transcription factors file (one per line)',
        default=None
    )
    parser.add_argument(
        '--seed',
        help='Random seed for reproducibility (default: 777)',
        type=int,
        default=777
    )
    parser.add_argument(
        '--limit',
        help='Return only the top N regulatory links',
        type=int,
        default=None
    )

    args = parser.parse_args()

    run_grn_inference(
        expression_file=args.expression_file,
        output_file=args.output_file,
        algo=args.algo,
        tf_file=args.tf_file,
        seed=args.seed,
        limit=args.limit
    )
