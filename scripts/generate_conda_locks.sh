#!/usr/bin/env bash

# Generate conda-lock files for the supported production starter platforms.

set -euo pipefail

if ! command -v conda-lock >/dev/null 2>&1; then
    echo "conda-lock is required. Install it with: micromamba install -n base -c conda-forge conda-lock" >&2
    exit 1
fi

conda-lock lock \
  -f envs/scanpy.yml \
  -p linux-64 \
  -p osx-arm64 \
  --lockfile envs/scanpy.conda-lock.yml

conda-lock lock \
  -f envs/seurat.yml \
  -p linux-64 \
  -p osx-arm64 \
  --lockfile envs/seurat.conda-lock.yml
