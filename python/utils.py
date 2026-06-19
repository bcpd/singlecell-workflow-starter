"""Utility functions for scRNA-seq starter workflows."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd

CONTRACT_VERSION = "1.0.0"
DEFAULT_SPECIES = "human"

REQUIRED_SAMPLESHEET_COLUMNS = ("sample", "matrix_dir")
OPTIONAL_SAMPLESHEET_COLUMNS = ("species", "genome", "mt_prefix")
VALID_ENGINES = {"scanpy": "h5ad", "seurat": "rds"}


def ensure_outdir(path: str | Path) -> Path:
    """Create and return an output directory path."""
    outdir = Path(path)
    outdir.mkdir(parents=True, exist_ok=True)
    return outdir


def default_mt_prefix(species: str = DEFAULT_SPECIES, mt_prefix: str | None = None) -> str:
    """Return a mitochondrial gene prefix after applying species defaults."""
    if mt_prefix is not None and str(mt_prefix).strip():
        return str(mt_prefix).strip()

    normalized_species = str(species or DEFAULT_SPECIES).strip().lower()
    if normalized_species in {"mouse", "mus musculus", "mm10", "grcm38", "grcm39"}:
        return "mt-"
    return "MT-"


def mitochondrial_gene_mask(gene_names: Iterable[str], prefix: str = "MT-") -> np.ndarray:
    """Return a boolean mask for mitochondrial genes.

    Parameters
    ----------
    gene_names:
        Gene symbols or feature names.
    prefix:
        Prefix used to identify mitochondrial genes. Human symbols often use ``MT-``.
    """
    return np.array([str(gene).upper().startswith(prefix.upper()) for gene in gene_names])


def normalize_samplesheet(samplesheet: pd.DataFrame) -> pd.DataFrame:
    """Validate and normalize a downstream-analysis samplesheet."""
    missing = [col for col in REQUIRED_SAMPLESHEET_COLUMNS if col not in samplesheet.columns]
    if missing:
        raise ValueError(f"Samplesheet is missing required columns: {', '.join(missing)}")

    normalized = samplesheet.copy()
    for col in OPTIONAL_SAMPLESHEET_COLUMNS:
        if col not in normalized.columns:
            normalized[col] = ""

    normalized["sample"] = normalized["sample"].astype(str).str.strip()
    normalized["matrix_dir"] = normalized["matrix_dir"].astype(str).str.strip()
    normalized["species"] = normalized["species"].replace("", DEFAULT_SPECIES).fillna(DEFAULT_SPECIES)
    normalized["species"] = normalized["species"].astype(str).str.strip().replace("", DEFAULT_SPECIES)
    normalized["genome"] = normalized["genome"].fillna("").astype(str).str.strip()
    normalized["mt_prefix"] = [
        default_mt_prefix(species, prefix if not pd.isna(prefix) else None)
        for species, prefix in zip(normalized["species"], normalized["mt_prefix"], strict=True)
    ]

    empty_required = [
        col for col in REQUIRED_SAMPLESHEET_COLUMNS if normalized[col].astype(str).str.len().eq(0).any()
    ]
    if empty_required:
        raise ValueError(f"Samplesheet contains empty required values: {', '.join(empty_required)}")

    return normalized[list(REQUIRED_SAMPLESHEET_COLUMNS + OPTIONAL_SAMPLESHEET_COLUMNS)]


def read_samplesheet(path: str | Path) -> pd.DataFrame:
    """Read, validate, and normalize a downstream-analysis samplesheet."""
    return normalize_samplesheet(pd.read_csv(path))


def required_contract_paths(sample: str, engine: str) -> list[str]:
    """Return required relative output paths for an analysis engine."""
    if engine not in VALID_ENGINES:
        raise ValueError(f"Unsupported engine: {engine}")

    object_ext = VALID_ENGINES[engine]
    return [
        "cell_metadata_prefilter.csv",
        "cell_metadata.csv",
        "cluster_markers.csv",
        "run_summary.json",
        "output_manifest.json",
        "plots",
        f"objects/{sample}.{object_ext}",
    ]


def write_json(payload: dict, path: str | Path) -> None:
    """Write JSON with stable formatting after creating the parent directory."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


def write_output_manifest(base_dir: str | Path, sample: str, engine: str) -> dict:
    """Write and return an output manifest for a completed analysis directory."""
    base_dir = Path(base_dir)
    required_paths = required_contract_paths(sample, engine)
    files = []
    for rel_path in required_paths:
        files.append(
            {
                "path": rel_path,
                "required": True,
                "exists": rel_path == "output_manifest.json" or (base_dir / rel_path).exists(),
            }
        )

    manifest = {
        "contract_version": CONTRACT_VERSION,
        "sample": sample,
        "engine": engine,
        "files": files,
    }
    write_json(manifest, base_dir / "output_manifest.json")
    return manifest


def write_dataframe(df: pd.DataFrame, path: str | Path) -> None:
    """Write a dataframe to CSV after creating its parent directory."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=True)
