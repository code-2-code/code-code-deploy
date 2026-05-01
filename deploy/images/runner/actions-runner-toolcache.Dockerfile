# syntax=docker/dockerfile:1

ARG ACTIONS_RUNNER_BASE_IMAGE=ghcr.io/actions/actions-runner:2.330.0

FROM ${ACTIONS_RUNNER_BASE_IMAGE}

ARG GO_VERSION=1.26.2
ARG GO_DOWNLOAD_BASE_URL=https://go.dev/dl
ARG GO_DOWNLOAD_FALLBACK_BASE_URL=
ARG HELM_VERSION=3.20.0
ARG HELM_DOWNLOAD_BASE_URL=https://get.helm.sh
ARG HELM_DOWNLOAD_FALLBACK_BASE_URL=
ARG APT_MIRROR=
ARG APT_DISABLE_THIRD_PARTY=false
ARG TARGETARCH=amd64

USER root

ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache \
    AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache \
    GOMODCACHE=/home/runner/.cache/go/pkg/mod \
    GOCACHE=/home/runner/.cache/go-build \
    NPM_CONFIG_CACHE=/home/runner/.cache/npm \
    npm_config_cache=/home/runner/.cache/npm \
    PIP_CACHE_DIR=/home/runner/.cache/pip \
    UV_CACHE_DIR=/home/runner/.cache/uv

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    set -eu; \
    restore_apt_sources() { \
      for backup_file in /tmp/apt-source-backups/*; do \
        [ -f "${backup_file}" ] || continue; \
        apt_file="/${backup_file#/tmp/apt-source-backups/}"; \
        mkdir -p "$(dirname "${apt_file}")"; \
        cp "${backup_file}" "${apt_file}"; \
      done; \
    }; \
    if [ -n "${APT_MIRROR}" ]; then \
      apt_mirror="${APT_MIRROR%/}"; \
      mkdir -p /tmp/apt-source-backups; \
      for apt_file in /etc/apt/sources.list /etc/apt/sources.list.d/*.sources; do \
        [ -f "${apt_file}" ] || continue; \
        backup_file="/tmp/apt-source-backups${apt_file}"; \
        mkdir -p "$(dirname "${backup_file}")"; \
        cp "${apt_file}" "${backup_file}"; \
        sed -i \
          -e "s#http://archive.ubuntu.com/ubuntu#${apt_mirror}#g" \
          -e "s#http://security.ubuntu.com/ubuntu#${apt_mirror}#g" \
          "${apt_file}"; \
      done; \
    fi; \
    if [ "${APT_DISABLE_THIRD_PARTY}" = "true" ]; then \
      for apt_file in /etc/apt/sources.list.d/*; do \
        [ -f "${apt_file}" ] || continue; \
        case "${apt_file}" in \
          */ubuntu.sources|*/ubuntu.list) continue ;; \
        esac; \
        mv "${apt_file}" "${apt_file}.disabled"; \
      done; \
    fi; \
    if ! apt-get update; then \
      restore_apt_sources; \
      apt-get update; \
    fi \
    && apt-get install -y --no-install-recommends ca-certificates curl make \
    && rm -rf /var/lib/apt/lists/* /tmp/apt-source-backups

RUN set -eu; \
    download_from_base() { \
      primary_base="${1%/}"; \
      fallback_base="${2%/}"; \
      artifact_path="$3"; \
      output_path="$4"; \
      if curl -fsSL "${primary_base}/${artifact_path}" -o "${output_path}"; then \
        return 0; \
      fi; \
      [ -n "${fallback_base}" ] || return 1; \
      curl -fsSL "${fallback_base}/${artifact_path}" -o "${output_path}"; \
    }; \
    case "${TARGETARCH}" in \
      amd64) go_arch=amd64; helm_arch=amd64 ;; \
      arm64) go_arch=arm64; helm_arch=arm64 ;; \
      *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    go_root="${RUNNER_TOOL_CACHE}/go/${GO_VERSION}/x64"; \
    if [ "${go_arch}" = "arm64" ]; then go_root="${RUNNER_TOOL_CACHE}/go/${GO_VERSION}/arm64"; fi; \
    mkdir -p "${go_root}" /tmp/go-install; \
    download_from_base "${GO_DOWNLOAD_BASE_URL}" "${GO_DOWNLOAD_FALLBACK_BASE_URL}" "go${GO_VERSION}.linux-${go_arch}.tar.gz" /tmp/go.tar.gz; \
    tar -xzf /tmp/go.tar.gz -C /tmp/go-install; \
    cp -a /tmp/go-install/go/. "${go_root}/"; \
    touch "${go_root}.complete"; \
    download_from_base "${HELM_DOWNLOAD_BASE_URL}" "${HELM_DOWNLOAD_FALLBACK_BASE_URL}" "helm-v${HELM_VERSION}-linux-${helm_arch}.tar.gz" /tmp/helm.tar.gz; \
    tar -xzf /tmp/helm.tar.gz -C /tmp; \
    install -m 0755 "/tmp/linux-${helm_arch}/helm" /usr/local/bin/helm; \
    mkdir -p /home/runner/.cache/go/pkg/mod /home/runner/.cache/go-build /home/runner/.cache/npm /home/runner/.cache/pip /home/runner/.cache/uv; \
    chown -R runner:runner "${RUNNER_TOOL_CACHE}" /home/runner/.cache; \
    rm -rf /tmp/go.tar.gz /tmp/go-install /tmp/helm.tar.gz "/tmp/linux-${helm_arch}"

USER runner
