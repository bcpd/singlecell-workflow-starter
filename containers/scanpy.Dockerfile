FROM mambaorg/micromamba:1.5.10

COPY --chown=$MAMBA_USER:$MAMBA_USER envs/scanpy.yml /tmp/environment.yml

RUN micromamba install --yes --name base --file /tmp/environment.yml \
    && micromamba clean --all --yes

ENV PATH=/opt/conda/bin:$PATH
