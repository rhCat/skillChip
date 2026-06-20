#!/usr/bin/env python3
"""
Compute velocity pseudotime and per-cell velocity quality metrics.

Runs, exactly as the upstream skill:
  * scv.tl.velocity_confidence(adata)   -> obs['velocity_length'], obs['velocity_confidence']
  * scv.tl.velocity_pseudotime(adata)   -> obs['velocity_pseudotime']

velocity_pseudotime is the model-agnostic ordering (works for any velocity mode),
complementary to the dynamical-model latent_time.

Writes the updated .h5ad with the new obs columns.

Examples:
    python velocity_pseudotime.py velocity.h5ad -o pseudotime.h5ad
"""

import argparse

from _common import add_io_args, configure_scvelo, info, load_adata, save_adata


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    add_io_args(p, default_output="velocity_pseudotime.h5ad")
    args = p.parse_args()

    scv = configure_scvelo(figdir=args.figdir)
    adata = load_adata(args.input)
    scv.tl.velocity_confidence(adata)
    scv.tl.velocity_pseudotime(adata)
    info("Computed velocity_confidence + velocity_length + velocity_pseudotime")
    save_adata(adata, args.output)


if __name__ == "__main__":
    main()
