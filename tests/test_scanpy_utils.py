"""Unit tests for lightweight Python utilities."""

from __future__ import annotations

import pandas as pd

from python.utils import (
    default_mt_prefix,
    ensure_outdir,
    mitochondrial_gene_mask,
    normalize_samplesheet,
    write_dataframe,
)


def test_mitochondrial_gene_mask_detects_human_mt_genes():
    """Human mitochondrial genes with MT- prefix should be detected."""
    genes = ["MT-CO1", "ACTB", "mt-nd1", "GAPDH"]
    mask = mitochondrial_gene_mask(genes)
    assert mask.tolist() == [True, False, True, False]


def test_default_mt_prefix_uses_species_defaults():
    """Human and mouse should use their common mitochondrial gene prefixes."""
    assert default_mt_prefix("human") == "MT-"
    assert default_mt_prefix("mouse") == "mt-"
    assert default_mt_prefix("human", "custom-") == "custom-"


def test_normalize_samplesheet_applies_optional_defaults():
    """Samplesheet normalization should fill optional metadata consistently."""
    samplesheet = pd.DataFrame({"sample": ["s1", "s2"], "matrix_dir": ["a", "b"], "species": ["human", "mouse"]})
    normalized = normalize_samplesheet(samplesheet)
    assert normalized["mt_prefix"].tolist() == ["MT-", "mt-"]
    assert normalized["genome"].tolist() == ["", ""]


def test_ensure_outdir_creates_directory(tmp_path):
    """ensure_outdir should create a requested output directory."""
    outdir = ensure_outdir(tmp_path / "nested" / "out")
    assert outdir.exists()
    assert outdir.is_dir()


def test_write_dataframe_creates_parent_directory(tmp_path):
    """write_dataframe should write CSV files after creating parent directories."""
    df = pd.DataFrame({"value": [1, 2, 3]})
    out_csv = tmp_path / "a" / "b" / "table.csv"
    write_dataframe(df, out_csv)
    assert out_csv.exists()
