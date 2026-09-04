# SigProfilerMatrixGenerator + SigProfilerAssignment with T2T-CHM13v2.0 support.
#
# Built from two forks while the upstream changes are under review:
#   * SigProfilerMatrixGenerator: ljwharbers/SigProfilerMatrixGenerator@worktree-chm13-support
#     (SigProfilerSuite/SigProfilerMatrixGenerator#250, adds the CHM13-T2T genome)
#   * SigProfilerAssignment: ljwharbers/SigProfilerAssignment@chm13-t2t-support
#     (adds CHM13-T2T-renormalised COSMIC SBS/DBS reference signatures)
# Built by .github/workflows/container.yml and published as
#   ghcr.io/ljwharbers/sigprofiler:<spmg version>-chm13-<SPMG_COMMIT>   (OCI image)
#   oras://ghcr.io/ljwharbers/sigprofiler-sif:<same tag>                 (Apptainer SIF)
# Genome payloads are not included: install them into a volume with
#   SigProfilerMatrixGenerator install <genome> [--local_genome <dir>] --volume <dir>
# and pass --volume <dir> to matrix_generator / cosmic_fit.

FROM python:3.12-slim

ARG SPMG_COMMIT=28a9ce8
ARG SPA_COMMIT=7417dda
ARG SPMG_VERSION=1.3.6

LABEL org.opencontainers.image.title="sigprofiler (CHM13-T2T)" \
      org.opencontainers.image.source="https://github.com/ljwharbers/SigProfilerMatrixGenerator" \
      org.opencontainers.image.revision="${SPMG_COMMIT}" \
      org.opencontainers.image.version="${SPMG_VERSION}-chm13-${SPMG_COMMIT}" \
      org.opencontainers.image.description="SigProfilerMatrixGenerator ${SPMG_VERSION} (ljwharbers@${SPMG_COMMIT}, CHM13-T2T genome) and SigProfilerAssignment (ljwharbers@${SPA_COMMIT}, CHM13-T2T COSMIC signatures)" \
      org.opencontainers.image.licenses="BSD-2-Clause"

# procps: Nextflow's task monitoring calls `ps` inside the container.
# git: needed by pip to install from the forks.
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

# pandas<3: SigProfilerAssignment 1.1.5's sample-reconstruction plots still use
# pandas 2 semantics (int() on a single-row Series).
# SETUPTOOLS_SCM_PRETEND_VERSION_FOR_...: pip's shallow git checkout carries no tags,
# so setuptools_scm would report 1.dev<N>+unknown and break SigProfilerAssignment's
# SigProfilerMatrixGenerator>=1.3.0 requirement.
RUN pip install --no-cache-dir --upgrade pip "setuptools>=69" wheel \
    && SETUPTOOLS_SCM_PRETEND_VERSION_FOR_SIGPROFILERMATRIXGENERATOR="${SPMG_VERSION}" \
       pip install --no-cache-dir "pandas>=2.2,<3" \
         "git+https://github.com/ljwharbers/SigProfilerMatrixGenerator.git@${SPMG_COMMIT}" \
         "git+https://github.com/ljwharbers/SigProfilerAssignment.git@${SPA_COMMIT}" \
    && apt-get purge -y git && apt-get autoremove -y

# Writable defaults for matplotlib and the SigProfilerAssignment template cache when
# the container runs as an arbitrary user (Nextflow/Apptainer).
ENV MPLCONFIGDIR=/tmp/matplotlib \
    HOME=/tmp

CMD ["SigProfilerMatrixGenerator", "--help"]
