#!/usr/bin/env python3
"""
Preprocess single-cell counts for RNA velocity.

Runs the standard scVelo preprocessing exactly as the upstream skill:
  1. scv.pp.filter_and_normalize(min_shared_counts, n_top_genes)
  2. sc.pp.neighbors  (only if 'neighbors' not already in adata.uns)
  3. scv.pp.moments    (first- and second-order moments over the kNN graph)

Writes a moments-ready .h5ad that velocity estimation can consume.

Examples:
    python preprocess.py data.h5ad -o preprocessed.h5ad
    python preprocess.py data.h5ad --n-top-genes 3000 --n-neighbors 30 -o pp.h5ad
"""

import argparse

from _common import (add_io_args, configure_scvelo, info, load_adata,
                     require_velocity_layers, save_adata)


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    add_io_args(p, default_output="preprocessed.h5ad")
    p.add_argument("--min-shared-counts", type=int, default=20,
                   help="Minimum counts in spliced+unspliced (default: 20)")
    p.add_argument("--n-top-genes", type=int, default=2000,
                   help="Number of top highly variable genes (default: 2000)")
    p.add_argument("--n-neighbors", type=int, default=30,
                   help="Neighbors for the kNN graph / moments (default: 30)")
    p.add_argument("--n-pcs", type=int, default=30,
                   help="PCA dimensions (default: 30)")
    args = p.parse_args()

    scv = configure_scvelo(figdir=args.figdir)
    adata = load_adata(args.input)
    require_velocity_layers(adata)
    info(f"Input: {adata.n_obs} cells x {adata.n_vars} genes")

    scv.pp.filter_and_normalize(adata, min_shared_counts=args.min_shared_counts,
                                n_top_genes=args.n_top_genes)

    if "neighbors" not in adata.uns:
        import scanpy as sc
        sc.pp.neighbors(adata, n_neighbors=args.n_neighbors, n_pcs=args.n_pcs)

    scv.pp.moments(adata, n_pcs=args.n_pcs, n_neighbors=args.n_neighbors)
    info(f"{adata.n_vars} velocity genes selected")
    save_adata(adata, args.output)


if __name__ == "__main__":
    main()
