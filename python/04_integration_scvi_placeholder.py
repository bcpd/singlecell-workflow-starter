#!/usr/bin/env python

"""Placeholder scaffold for scVI-based integration.

This file is intentionally conservative because scVI runs are more environment- and GPU-dependent.
Use it as a starting point after installing scvi-tools.
"""

from __future__ import annotations

import argparse

import scanpy as sc


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Prepare an AnnData object for scVI integration.")
    parser.add_argument("--input-h5ad", required=True, help="Input AnnData object")
    parser.add_argument("--batch-key", required=True, help="Column in adata.obs identifying batch/sample")
    parser.add_argument("--out-h5ad", default="results/scvi_integrated.h5ad", help="Output AnnData object")
    return parser.parse_args()


def main() -> None:
    """Run a minimal scVI integration workflow."""
    args = parse_args()

    # Import scvi lazily so the rest of the repository works without it.
    import scvi

    # Load AnnData and keep raw counts in a layer if available.
    adata = sc.read_h5ad(args.input_h5ad)

    # Set up AnnData for scVI. Adjust layer="counts" if your object stores raw counts there.
    scvi.model.SCVI.setup_anndata(adata, batch_key=args.batch_key)

    # Train the model with simple defaults.
    model = scvi.model.SCVI(adata)
    model.train()

    # Store the latent representation for downstream neighbors/UMAP/clustering.
    adata.obsm["X_scVI"] = model.get_latent_representation()
    sc.pp.neighbors(adata, use_rep="X_scVI")
    sc.tl.umap(adata)
    sc.tl.leiden(adata, key_added="leiden_scvi")

    # Save integrated object.
    adata.write_h5ad(args.out_h5ad)


if __name__ == "__main__":
    main()
