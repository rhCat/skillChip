#!/usr/bin/env python3
"""
Compute shared latent time from the dynamical velocity model.

Runs scv.tl.latent_time(adata), which averages per-gene latent times (weighted
by fit_likelihood) into a single pseudotime in obs['latent_time']. Requires that
velocity was fit with mode='dynamical' (recover_dynamics has run).

Writes the updated .h5ad with obs['latent_time'].

Examples:
    python latent_time.py velocity.h5ad -o latent.h5ad
"""

import argparse

from _common import add_io_args, configure_scvelo, info, load_adata, save_adata


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    add_io_args(p, default_output="latent_time.h5ad")
    args = p.parse_args()

    scv = configure_scvelo(figdir=args.figdir)
    adata = load_adata(args.input)
    scv.tl.latent_time(adata)
    info("Latent time computed -> obs['latent_time']")
    save_adata(adata, args.output)


if __name__ == "__main__":
    main()
