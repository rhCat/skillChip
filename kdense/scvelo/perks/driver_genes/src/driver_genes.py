#!/usr/bin/env python3
"""
Rank velocity driver genes per cluster group.

Runs scv.tl.rank_velocity_genes(groupby, min_corr) — which finds, for each group
in adata.obs[groupby], the genes whose velocity dynamics best explain the group's
transitions — and exports the resulting per-group name table to CSV via
scv.DataFrame(adata.uns['rank_velocity_genes']['names']).

Examples:
    python driver_genes.py velocity.h5ad --groupby clusters -o driver_genes.csv
    python driver_genes.py velocity.h5ad --groupby leiden --min-corr 0.3 -o drivers.csv
"""

import argparse

from _common import configure_scvelo, info, load_adata


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("input", help="Velocity-annotated AnnData (.h5ad)")
    p.add_argument("-o", "--output", default="driver_genes.csv",
                   help="Output CSV path (default: driver_genes.csv)")
    p.add_argument("--figdir", default="figures",
                   help="Directory for saved figures (default: figures)")
    p.add_argument("--groupby", default="clusters",
                   help="obs column with cluster/cell-type labels (default: clusters)")
    p.add_argument("--min-corr", type=float, default=0.3,
                   help="Minimum velocity correlation to rank a gene (default: 0.3)")
    args = p.parse_args()

    scv = configure_scvelo(figdir=args.figdir)
    adata = load_adata(args.input)

    if args.groupby not in adata.obs.columns:
        from _common import die
        die(f"groupby column '{args.groupby}' not in adata.obs")

    scv.tl.rank_velocity_genes(adata, groupby=args.groupby, min_corr=args.min_corr)
    df = scv.DataFrame(adata.uns["rank_velocity_genes"]["names"])
    df.to_csv(args.output, index=False)
    info(f"Wrote {len(df)} ranked rows x {df.shape[1]} groups -> {args.output}")


if __name__ == "__main__":
    main()
