#!/usr/bin/env python3
"""
End-to-end RNA velocity pipeline in one command.

Thin CLI driver around the vendored upstream workflow
(rna_velocity_workflow.run_velocity_analysis): loads an AnnData .h5ad (or
velocyto .loom) and runs preprocess -> velocity -> graph -> latent time ->
confidence -> pseudotime -> driver genes -> figures, writing
<output_dir>/adata_velocity.h5ad plus the figure set.

Examples:
    python run_workflow.py data.h5ad --groupby clusters --mode dynamical -o results
    python run_workflow.py data.h5ad --mode stochastic --output-dir results
"""

import argparse

from _common import configure_scvelo, info, load_adata
from rna_velocity_workflow import run_velocity_analysis


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("input", help="Input AnnData (.h5ad) or velocyto (.loom)")
    p.add_argument("-o", "--output-dir", default="velocity_results",
                   help="Directory for outputs + figures (default: velocity_results)")
    p.add_argument("--groupby", default="clusters",
                   help="obs column with cluster/cell-type labels (default: clusters)")
    p.add_argument("--n-top-genes", type=int, default=2000,
                   help="Number of top highly variable genes (default: 2000)")
    p.add_argument("--n-neighbors", type=int, default=30,
                   help="Neighbors for moments (default: 30)")
    p.add_argument("--mode", default="dynamical",
                   choices=["stochastic", "deterministic", "dynamical"],
                   help="Velocity model (default: dynamical)")
    p.add_argument("--n-jobs", type=int, default=4,
                   help="Parallel jobs for dynamical model (default: 4)")
    args = p.parse_args()

    # Touch scvelo settings via the shared helper so figdir/verbosity match the
    # rest of the cartridge (the vendored workflow also sets figdir internally).
    configure_scvelo(figdir=args.output_dir)
    adata = load_adata(args.input)
    info(f"Running full velocity workflow (mode={args.mode}) on "
         f"{adata.n_obs} cells x {adata.n_vars} genes")

    run_velocity_analysis(
        adata,
        groupby=args.groupby,
        n_top_genes=args.n_top_genes,
        n_neighbors=args.n_neighbors,
        mode=args.mode,
        n_jobs=args.n_jobs,
        output_dir=args.output_dir,
    )


if __name__ == "__main__":
    main()
