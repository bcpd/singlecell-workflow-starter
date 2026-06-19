#!/usr/bin/env bash

# Example Cell Ranger count command.
# Cell Ranger must be installed separately and available on PATH.

set -euo pipefail

SAMPLE_ID="${1:-pbmc1k}"
FASTQS="${2:-/absolute/path/to/fastqs}"
TRANSCRIPTOME="${3:-/absolute/path/to/refdata-gex-GRCh38-2024-A}"
EXPECTED_CELLS="${4:-1000}"

cellranger count \
  --id="${SAMPLE_ID}" \
  --fastqs="${FASTQS}" \
  --sample="${SAMPLE_ID}" \
  --transcriptome="${TRANSCRIPTOME}" \
  --expect-cells="${EXPECTED_CELLS}"
