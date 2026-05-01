# syntax=docker/dockerfile:1

ARG ACTIONS_RUNNER_BASE_IMAGE=ghcr.io/actions/actions-runner:2.333.1

FROM ${ACTIONS_RUNNER_BASE_IMAGE}

ARG GO_VERSION=1.26.2
ARG GO_DOWNLOAD_BASE_URL=https://go.dev/dl
ARG GO_DOWNLOAD_FALLBACK_BASE_URL=
ARG HELM_VERSION=3.20.0
ARG HELM_DOWNLOAD_BASE_URL=https://get.helm.sh
ARG HELM_DOWNLOAD_FALLBACK_BASE_URL=
ARG NODE_VERSION=24.15.0
ARG NODE_DOWNLOAD_BASE_URL=https://nodejs.org/dist
ARG NODE_DOWNLOAD_FALLBACK_BASE_URL=
ARG PNPM_VERSION=10.33.0
ARG BUF_VERSION=1.69.0
ARG BUF_DOWNLOAD_BASE_URL=https://github.com/bufbuild/buf/releases/download
ARG BUF_DOWNLOAD_FALLBACK_BASE_URL=
ARG PROTOC_GEN_GO_VERSION=1.36.11
ARG PROTOC_GEN_GO_GRPC_VERSION=1.5.1
ARG PROTOC_GEN_CONNECT_GO_VERSION=1.19.2
ARG PROTOC_GEN_ES_VERSION=2.11.0
ARG NPM_CONFIG_REGISTRY=
ARG GOPROXY=
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
    PNPM_HOME=/home/runner/.cache/pnpm \
    XDG_DATA_HOME=/home/runner/.cache \
    PIP_CACHE_DIR=/home/runner/.cache/pip \
    UV_CACHE_DIR=/home/runner/.cache/uv \
    COREPACK_HOME=/home/runner/.cache/corepack

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
    && apt-get install -y --no-install-recommends ca-certificates curl make xz-utils \
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
      amd64) go_arch=amd64; helm_arch=amd64; node_arch=x64; buf_arch=x86_64 ;; \
      arm64) go_arch=arm64; helm_arch=arm64; node_arch=arm64; buf_arch=aarch64 ;; \
      *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    go_root="${RUNNER_TOOL_CACHE}/go/${GO_VERSION}/x64"; \
    if [ "${go_arch}" = "arm64" ]; then go_root="${RUNNER_TOOL_CACHE}/go/${GO_VERSION}/arm64"; fi; \
    node_root="${RUNNER_TOOL_CACHE}/node/${NODE_VERSION}/x64"; \
    if [ "${node_arch}" = "arm64" ]; then node_root="${RUNNER_TOOL_CACHE}/node/${NODE_VERSION}/arm64"; fi; \
    mkdir -p "${go_root}" "${node_root}" /tmp/go-install /tmp/node-install /tmp/buf-install; \
    download_from_base "${GO_DOWNLOAD_BASE_URL}" "${GO_DOWNLOAD_FALLBACK_BASE_URL}" "go${GO_VERSION}.linux-${go_arch}.tar.gz" /tmp/go.tar.gz; \
    tar -xzf /tmp/go.tar.gz -C /tmp/go-install; \
    cp -a /tmp/go-install/go/. "${go_root}/"; \
    touch "${go_root}.complete"; \
    download_from_base "${NODE_DOWNLOAD_BASE_URL}" "${NODE_DOWNLOAD_FALLBACK_BASE_URL}" "v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" /tmp/node.tar.xz; \
    tar -xJf /tmp/node.tar.xz -C /tmp/node-install --strip-components=1; \
    cp -a /tmp/node-install/. "${node_root}/"; \
    touch "${node_root}.complete"; \
    ln -sf "${node_root}/bin/node" /usr/local/bin/node; \
    ln -sf "${node_root}/bin/npm" /usr/local/bin/npm; \
    ln -sf "${node_root}/bin/npx" /usr/local/bin/npx; \
    download_from_base "${HELM_DOWNLOAD_BASE_URL}" "${HELM_DOWNLOAD_FALLBACK_BASE_URL}" "helm-v${HELM_VERSION}-linux-${helm_arch}.tar.gz" /tmp/helm.tar.gz; \
    tar -xzf /tmp/helm.tar.gz -C /tmp; \
    install -m 0755 "/tmp/linux-${helm_arch}/helm" /usr/local/bin/helm; \
    download_from_base "${BUF_DOWNLOAD_BASE_URL}" "${BUF_DOWNLOAD_FALLBACK_BASE_URL}" "v${BUF_VERSION}/buf-Linux-${buf_arch}.tar.gz" /tmp/buf.tar.gz; \
    tar -xzf /tmp/buf.tar.gz -C /tmp/buf-install --strip-components=1; \
    install -m 0755 /tmp/buf-install/bin/buf /usr/local/bin/buf; \
    if [ -n "${NPM_CONFIG_REGISTRY}" ]; then npm config set registry "${NPM_CONFIG_REGISTRY}"; fi; \
    npm install -g "pnpm@${PNPM_VERSION}" "@bufbuild/protoc-gen-es@${PROTOC_GEN_ES_VERSION}"; \
    ln -sf "${node_root}/bin/pnpm" /usr/local/bin/pnpm; \
    ln -sf "${node_root}/bin/protoc-gen-es" /usr/local/bin/protoc-gen-es; \
    export PATH="${go_root}/bin:${PATH}" GOBIN=/usr/local/bin GOTOOLCHAIN=local; \
    if [ -n "${GOPROXY}" ]; then export GOPROXY; fi; \
    go install "google.golang.org/protobuf/cmd/protoc-gen-go@v${PROTOC_GEN_GO_VERSION}"; \
    go install "google.golang.org/grpc/cmd/protoc-gen-go-grpc@v${PROTOC_GEN_GO_GRPC_VERSION}"; \
    go install "connectrpc.com/connect/cmd/protoc-gen-connect-go@v${PROTOC_GEN_CONNECT_GO_VERSION}"; \
    mkdir -p /home/runner/.cache/go/pkg/mod /home/runner/.cache/go-build /home/runner/.cache/npm /home/runner/.cache/pnpm/store /home/runner/.cache/pip /home/runner/.cache/uv /home/runner/.cache/corepack; \
    chown -R runner:runner "${RUNNER_TOOL_CACHE}" /home/runner/.cache; \
    rm -rf /tmp/go.tar.gz /tmp/go-install /tmp/node.tar.xz /tmp/node-install /tmp/helm.tar.gz "/tmp/linux-${helm_arch}" /tmp/buf.tar.gz /tmp/buf-install

USER runner
