#!/usr/bin/env python3
"""
plot_entry — render a volcano plot and an MA plot from a DESeq2 results CSV.

Self-contained re-implementation of the `create_plots` stage of the source
run_deseq2_analysis.py (kept alongside for provenance). It reads a results CSV
with the standard DESeq2 columns (baseMean, log2FoldChange, padj) and renders
the two diagnostic plots with the same styling. Pure matplotlib + numpy +
pandas, so it runs fully offline WITHOUT importing pydeseq2.

Env:
    RESULTS      path to a DESeq2 results CSV (index = genes; needs
                 columns log2FoldChange, padj, baseMean)
    OUT_DIR      directory for the plot PNGs (required; usually RECORD_STORE)
    ALPHA        significance threshold for colouring (default 0.05)
"""

import os
import sys

import matplotlib

matplotlib.use("Agg")  # headless / offline rendering
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402


def main():
    results_path = os.environ["RESULTS"]
    out_dir = os.environ["OUT_DIR"]
    alpha = float(os.environ.get("ALPHA", "0.05"))

    results = pd.read_csv(results_path, index_col=0)

    # Volcano plot ---------------------------------------------------------
    results["-log10(padj)"] = -np.log10(results.padj.fillna(1))
    significant = results.padj < alpha

    plt.figure(figsize=(10, 6))
    plt.scatter(
        results.loc[~significant, "log2FoldChange"],
        results.loc[~significant, "-log10(padj)"],
        alpha=0.3, s=10, c="gray", label="Not significant",
    )
    plt.scatter(
        results.loc[significant, "log2FoldChange"],
        results.loc[significant, "-log10(padj)"],
        alpha=0.6, s=10, c="red", label=f"Significant (padj < {alpha})",
    )
    plt.axhline(-np.log10(alpha), color="blue", linestyle="--", linewidth=1, alpha=0.5)
    plt.axvline(1, color="gray", linestyle="--", linewidth=1, alpha=0.5)
    plt.axvline(-1, color="gray", linestyle="--", linewidth=1, alpha=0.5)
    plt.xlabel("Log2 Fold Change", fontsize=12)
    plt.ylabel("-Log10(Adjusted P-value)", fontsize=12)
    plt.title("Volcano Plot", fontsize=14, fontweight="bold")
    plt.legend()
    plt.tight_layout()
    volcano_path = os.path.join(out_dir, "volcano_plot.png")
    plt.savefig(volcano_path, dpi=300)
    plt.close()

    # MA plot --------------------------------------------------------------
    plt.figure(figsize=(10, 6))
    plt.scatter(
        np.log10(results.loc[~significant, "baseMean"] + 1),
        results.loc[~significant, "log2FoldChange"],
        alpha=0.3, s=10, c="gray", label="Not significant",
    )
    plt.scatter(
        np.log10(results.loc[significant, "baseMean"] + 1),
        results.loc[significant, "log2FoldChange"],
        alpha=0.6, s=10, c="red", label=f"Significant (padj < {alpha})",
    )
    plt.axhline(0, color="blue", linestyle="--", linewidth=1, alpha=0.5)
    plt.xlabel("Log10(Base Mean + 1)", fontsize=12)
    plt.ylabel("Log2 Fold Change", fontsize=12)
    plt.title("MA Plot", fontsize=14, fontweight="bold")
    plt.legend()
    plt.tight_layout()
    ma_path = os.path.join(out_dir, "ma_plot.png")
    plt.savefig(ma_path, dpi=300)
    plt.close()

    print(
        f"{{\"tool\":\"render_plots\",\"status\":\"ok\","
        f"\"volcano\":\"{volcano_path}\",\"ma\":\"{ma_path}\","
        f"\"n_genes\":{len(results)}}}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
