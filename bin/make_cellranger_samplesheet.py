#!/usr/bin/env python

"""Create a simple Cell Ranger samplesheet from FASTQ folders.

This utility is intentionally minimal and assumes one folder per sample.
It is useful for turning public 10x FASTQ downloads into a reviewable table.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Create a Cell Ranger-style sample table.")
    parser.add_argument("--fastq-root", required=True, help="Directory containing one FASTQ folder per sample")
    parser.add_argument("--transcriptome", required=True, help="Cell Ranger transcriptome path")
    parser.add_argument("--expected-cells", type=int, default=3000, help="Expected cells per sample")
    parser.add_argument("--out-csv", default="data/samplesheets/cellranger_samplesheet.csv", help="Output CSV")
    return parser.parse_args()


def main() -> None:
    """Build a samplesheet from sample directories."""
    args = parse_args()
    fastq_root = Path(args.fastq_root)

    rows = []
    for sample_dir in sorted([p for p in fastq_root.iterdir() if p.is_dir()]):
        rows.append(
            {
                "sample": sample_dir.name,
                "fastqs": str(sample_dir.resolve()),
                "transcriptome": args.transcriptome,
                "expected_cells": args.expected_cells,
                "chemistry": "auto",
            }
        )

    out_csv = Path(args.out_csv)
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(rows).to_csv(out_csv, index=False)


if __name__ == "__main__":
    main()
