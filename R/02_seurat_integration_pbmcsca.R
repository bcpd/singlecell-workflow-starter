#!/usr/bin/env Rscript

# Seurat v5 integration example using the SeuratData pbmcsca dataset.
# This script demonstrates how to compare an unintegrated analysis with an integrated analysis.
# It is intended as a portfolio module, not as a universal integration benchmark.

suppressPackageStartupMessages({
  library(optparse)
  library(Seurat)
  library(SeuratData)
  library(ggplot2)
  library(patchwork)
})

option_list <- list(
  make_option("--outdir", type = "character", default = "results/seurat_pbmcsca_integration", help = "Output directory")
)

opt <- parse_args(OptionParser(option_list = option_list))
dir.create(opt$outdir, recursive = TRUE, showWarnings = FALSE)

# Install pbmcsca on first use if it is not already available.
if (!"pbmcsca" %in% InstalledData()[, "Dataset"]) {
  InstallData("pbmcsca")
}

# Load the PBMC single-cell assay comparison dataset.
data("pbmcsca")
obj <- pbmcsca

# Use RNA assay and standard log normalization for a compact example.
DefaultAssay(obj) <- "RNA"
obj <- NormalizeData(obj)
obj <- FindVariableFeatures(obj)
obj <- ScaleData(obj)
obj <- RunPCA(obj)

# Visualize batch/technology effects before integration.
obj <- RunUMAP(obj, dims = 1:30, reduction.name = "umap.unintegrated")
p_unintegrated <- DimPlot(obj, reduction = "umap.unintegrated", group.by = "Method")
ggsave(file.path(opt$outdir, "umap_unintegrated_by_method.png"), p_unintegrated, width = 8, height = 5, dpi = 150)

# Integrate with CCA. Extend this block for RPCAIntegration, HarmonyIntegration, or scVIIntegration.
obj <- IntegrateLayers(
  object = obj,
  method = CCAIntegration,
  orig.reduction = "pca",
  new.reduction = "integrated.cca",
  verbose = FALSE
)

# Cluster and visualize the integrated representation.
obj <- FindNeighbors(obj, reduction = "integrated.cca", dims = 1:30)
obj <- FindClusters(obj, resolution = 0.5)
obj <- RunUMAP(obj, reduction = "integrated.cca", dims = 1:30, reduction.name = "umap.integrated")

p_integrated_method <- DimPlot(obj, reduction = "umap.integrated", group.by = "Method")
p_integrated_celltype <- DimPlot(obj, reduction = "umap.integrated", group.by = "CellType", label = TRUE, repel = TRUE)

ggsave(file.path(opt$outdir, "umap_integrated_by_method.png"), p_integrated_method, width = 8, height = 5, dpi = 150)
ggsave(file.path(opt$outdir, "umap_integrated_by_celltype.png"), p_integrated_celltype, width = 9, height = 6, dpi = 150)

# Save the integrated object.
saveRDS(obj, file.path(opt$outdir, "pbmcsca_integrated_cca.rds"))
