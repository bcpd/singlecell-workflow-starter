#!/usr/bin/env python

"""Annotate a Scanpy AnnData object with CellTypist.

CellTypist expects normalized/log-transformed data for typical workflows.
For PBMC demos, built-in immune models are often a useful starting point.
"""

from __future__ import annotations

import argparse

import celltypist
import scanpy as sc

from utils import ensure_outdir


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Run CellTypist annotation on an h5ad file.")
    parser.add_argument("--input-h5ad", required=True, help="Input AnnData h5ad file")
    parser.add_argument("--outdir", default="results/celltypist", help="Output directory")
    parser.add_argument("--model", default="Immune_All_Low.pkl", help="CellTypist model name")
    parser.add_argument("--majority-voting", action="store_true", help="Enable majority-voting refinement")
    return parser.parse_args()


def main() -> None:
    """Run CellTypist and write annotated outputs."""
    args = parse_args()
    outdir = ensure_outdir(args.outdir)

    # Load the AnnData object created by the Scanpy workflow.
    adata = sc.read_h5ad(args.input_h5ad)

    # Download/load the requested model if necessary.
    celltypist.models.download_models(model=[args.model], force_update=False)

    # Predict cell types.
    predictions = celltypist.annotate(
        adata,
        model=args.model,
        majority_voting=args.majority_voting,
    )

    # Convert predictions back to an AnnData object.
    annotated = predictions.to_adata()

    # Save predicted labels and confidence scores.
    annotated.obs.to_csv(outdir / "celltypist_predictions.csv")
    annotated.write_h5ad(outdir / "celltypist_annotated.h5ad")

    # Plot predicted labels if UMAP coordinates are available.
    if "X_umap" in annotated.obsm:
        sc.settings.figdir = str(outdir)
        color_key = "majority_voting" if args.majority_voting else "predicted_labels"
        sc.pl.umap(annotated, color=color_key, save="_celltypist_labels.png", show=False)


if __name__ == "__main__":
    main()
