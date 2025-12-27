# Custom Jupyter Notebook Image for Educational Platform
# Based on jupyter/scipy-notebook with additional packages
# Includes: Python, R, Julia, Octave, LaTeX, and scientific computing tools

FROM jupyter/scipy-notebook:latest

LABEL maintainer="Educational Platform"
LABEL description="Multi-language Jupyter notebook with scientific computing packages"

# Switch to root for system installations
USER root

# ===========================================
# System Dependencies
# ===========================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Compilers
    gcc \
    g++ \
    gfortran \
    make \
    cmake \
    # LaTeX for PDF export
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-latex-extra \
    texlive-plain-generic \
    latexmk \
    pandoc \
    # Version control
    git \
    # Utilities
    wget \
    curl \
    vim \
    htop \
    # GNU Octave
    octave \
    octave-control \
    octave-image \
    octave-io \
    octave-optim \
    octave-signal \
    octave-statistics \
    # R dependencies
    r-base \
    r-base-dev \
    # Additional libraries
    libpq-dev \
    libgeos-dev \
    libproj-dev \
    libgdal-dev \
    libffi-dev \
    libssl-dev \
    libblas-dev \
    liblapack-dev \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ===========================================
# Julia Installation
# ===========================================
ENV JULIA_VERSION=1.10.0
ENV JULIA_PATH=/opt/julia

RUN mkdir -p ${JULIA_PATH} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C ${JULIA_PATH} --strip-components=1 && \
    rm julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    ln -s ${JULIA_PATH}/bin/julia /usr/local/bin/julia

# ===========================================
# Switch to notebook user for package installations
# ===========================================
USER ${NB_UID}

# ===========================================
# Python Packages - Core Scientific
# ===========================================
COPY --chown=${NB_UID}:${NB_GID} requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# ===========================================
# R Packages and Kernel
# ===========================================
RUN mamba install -y -c conda-forge \
    r-essentials \
    r-irkernel \
    r-tidyverse \
    r-ggplot2 \
    r-dplyr \
    r-shiny \
    r-rmarkdown \
    r-knitr \
    r-devtools \
    r-caret \
    r-randomforest \
    r-plotly \
    && mamba clean --all -f -y

# Register R kernel
RUN R -e "IRkernel::installspec(user = FALSE)"

# ===========================================
# Julia Packages and Kernel
# ===========================================
ENV JULIA_DEPOT_PATH=/opt/julia-depot
USER root
RUN mkdir -p ${JULIA_DEPOT_PATH} && \
    chown -R ${NB_UID}:${NB_GID} ${JULIA_DEPOT_PATH}
USER ${NB_UID}

# Install Julia packages (this can take a while)
RUN julia -e 'using Pkg; \
    Pkg.add(["IJulia", "Plots", "DataFrames", "CSV", "DifferentialEquations", "LinearAlgebra", "Statistics"]); \
    using IJulia; \
    installkernel("Julia")'

# ===========================================
# Octave Kernel
# ===========================================
RUN pip install --no-cache-dir octave_kernel

# ===========================================
# Bash Kernel
# ===========================================
RUN pip install --no-cache-dir bash_kernel && \
    python -m bash_kernel.install

# ===========================================
# SQL Kernel
# ===========================================
RUN pip install --no-cache-dir ipython-sql

# ===========================================
# Jupyter Extensions
# ===========================================
RUN pip install --no-cache-dir \
    jupyterlab-git \
    jupyterlab-latex \
    jupyter-resource-usage \
    nbgitpuller

# Enable extensions
RUN jupyter labextension enable jupyterlab-git && \
    jupyter server extension enable jupyterlab_git

# ===========================================
# Create shared directory
# ===========================================
USER root
RUN mkdir -p /home/jovyan/shared && \
    chown -R ${NB_UID}:${NB_GID} /home/jovyan/shared

# ===========================================
# Environment Variables
# ===========================================
ENV JUPYTER_ENABLE_LAB=yes
ENV SHELL=/bin/bash

# ===========================================
# Final Setup
# ===========================================
USER ${NB_UID}
WORKDIR /home/jovyan

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8888/api || exit 1

# Default command
CMD ["start-notebook.sh"]
