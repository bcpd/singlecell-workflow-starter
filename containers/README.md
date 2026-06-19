# Project containers

Build these images before running the local Nextflow workflow with `-profile docker`.

```bash
docker build -f containers/scanpy.Dockerfile -t single-cell-workflows-starter-scanpy:0.1.0 .
docker build -f containers/seurat.Dockerfile -t single-cell-workflows-starter-seurat:0.1.0 .
```

The Docker profile uses these local tags in `conf/docker.config`.
