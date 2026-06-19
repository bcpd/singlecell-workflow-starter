#!/usr/bin/env bash

# Example nf-core/scrnaseq command.
# Edit paths and parameters before running.
#
# This is provided as a production-style alternative to maintaining your own FASTQ-to-counts pipeline.

set -euo pipefail

SAMPLESHEET="data/samplesheets/nfcore_scrnaseq_samplesheet.csv"
OUTDIR="results/nfcore_scrnaseq"
GENOME="GRCh38"

cat <<EOF
Edit ${SAMPLESHEET} first, then run something like:

nextflow run nf-core/scrnaseq \
  -profile docker \
  --input ${SAMPLESHEET} \
  --outdir ${OUTDIR} \
  --genome ${GENOME} \
  --aligner cellranger

For open-source quantification alternatives, review nf-core/scrnaseq parameters for STARsolo,
kallisto/bustools, or SimpleAF/Alevin-Fry.
EOF
