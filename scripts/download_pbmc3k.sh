#!/usr/bin/env bash

# Download the canonical 10x PBMC 3k filtered matrix used in many Seurat/Scanpy tutorials.
# The script stores data under data/raw and avoids committing large files to Git.

set -euo pipefail

OUTDIR="data/raw/pbmc3k"
URL="https://cf.10xgenomics.com/samples/cell-exp/1.1.0/pbmc3k/pbmc3k_filtered_gene_bc_matrices.tar.gz"
TARBALL="${OUTDIR}/pbmc3k_filtered_gene_bc_matrices.tar.gz"
SHA256="847d6ebd9a1ec9a768f2be7e40ca42cbfe75ebeb6d76a4c24167041699dc28b5"

verify_checksum() {
    local actual
    actual="$(shasum -a 256 "${TARBALL}")"
    actual="${actual%% *}"

    if [[ "${actual}" != "${SHA256}" ]]; then
        echo "Checksum mismatch for ${TARBALL}" >&2
        echo "Expected: ${SHA256}" >&2
        echo "Actual:   ${actual}" >&2
        exit 1
    fi
}

mkdir -p "${OUTDIR}"

if [[ ! -f "${TARBALL}" ]]; then
    echo "Downloading PBMC 3k matrix..."
    curl -L "${URL}" -o "${TARBALL}"
else
    echo "Tarball already exists: ${TARBALL}"
fi

echo "Verifying PBMC 3k tarball checksum..."
verify_checksum

echo "Extracting PBMC 3k matrix..."
tar -xzf "${TARBALL}" -C "${OUTDIR}"

echo "Done. Matrix directory:"
echo "${OUTDIR}/filtered_gene_bc_matrices/hg19"
