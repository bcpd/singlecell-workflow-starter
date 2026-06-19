# Install R packages used by the Seurat/Monocle scripts.
# Some packages are installed from CRAN and others from Bioconductor/GitHub.

cran_packages <- c(
  "optparse",
  "ggplot2",
  "dplyr",
  "patchwork",
  "jsonlite",
  "remotes"
)

for (pkg in cran_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

if (!requireNamespace("Seurat", quietly = TRUE)) {
  install.packages("Seurat", repos = "https://cloud.r-project.org")
}

if (!requireNamespace("SeuratData", quietly = TRUE)) {
  remotes::install_github("satijalab/seurat-data")
}

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org")
}

bioc_packages <- c("SingleR", "celldex", "SingleCellExperiment")

for (pkg in bioc_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    BiocManager::install(pkg, ask = FALSE, update = FALSE)
  }
}

# Monocle3 is optional because installation can be more environment-specific.
if (!requireNamespace("monocle3", quietly = TRUE)) {
  message("monocle3 is not installed. Install from the Monocle3 documentation if running trajectory scripts.")
}
