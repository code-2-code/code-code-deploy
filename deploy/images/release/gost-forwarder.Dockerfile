# syntax=docker/dockerfile:1

ARG GOST_IMAGE=gogost/gost:3.2.6
FROM ${GOST_IMAGE}

ARG OCI_SOURCE=""
ARG OCI_REVISION=""
ARG OCI_VERSION=""

LABEL org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.version="${OCI_VERSION}"
