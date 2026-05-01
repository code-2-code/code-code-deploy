#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${GITHUB_ACTIONS:-}" == "true" && -f "${repo_root}/deploy/.env" ]]; then
  echo "::error::deploy/.env must stay local and must not be present in public CI."
  exit 1
fi

credential_pattern='(://[^/@[:space:]]+:[^/@[:space:]]+@|(^|[?&])[^=]*(token|password|passwd|secret|apikey|api_key|auth)[^=]*=|_authToken=|Authorization:)'
guarded_names=(
  IMAGE_REGISTRY
  BUILD_NPM_REGISTRY
  BUILD_GOPROXY
  BUILD_PIP_INDEX_URL
  BUILD_DEBIAN_MIRROR
  GO_BASE_IMAGE
  NODE_BASE_IMAGE
  NODE_SLIM_BASE_IMAGE
  NGINX_UNPRIVILEGED_BASE_IMAGE
  ACTIONS_RUNNER_BASE_IMAGE
  ACTIONS_RUNNER_GO_DOWNLOAD_BASE_URL
  ACTIONS_RUNNER_GO_DOWNLOAD_FALLBACK_BASE_URL
  ACTIONS_RUNNER_HELM_DOWNLOAD_BASE_URL
  ACTIONS_RUNNER_HELM_DOWNLOAD_FALLBACK_BASE_URL
  ACTIONS_RUNNER_APT_MIRROR
  ACTIONS_RUNNER_APT_DISABLE_THIRD_PARTY
  ACTIONS_RUNNER_IMAGE
  REGISTRY_CACHE_HTTP_PROXY
  REGISTRY_CACHE_HTTPS_PROXY
  REGISTRY_CACHE_NO_PROXY
  RUNNER_GOPROXY
  RUNNER_GOSUMDB
  RUNNER_GOPRIVATE
  RUNNER_NPM_REGISTRY
  RUNNER_PIP_INDEX_URL
  RUNNER_UV_INDEX_URL
  GO_DOWNLOAD_BASE_URL
  GOPROXY
  GOSUMDB
  GOPRIVATE
  NPM_CONFIG_REGISTRY
  npm_config_registry
  PIP_INDEX_URL
  UV_INDEX_URL
  HTTP_PROXY
  HTTPS_PROXY
  NO_PROXY
  http_proxy
  https_proxy
  no_proxy
  ARC_CONTROLLER_HELM_ARGS
  ARC_RUNNER_HELM_ARGS
  REGISTRY_HELM_ARGS
  KIALI_OPERATOR_HELM_ARGS
  INFRASTRUCTURE_ADDONS_HELM_ARGS
)

for name in "${guarded_names[@]}"; do
  value="${!name:-}"
  if [[ -z "${value}" ]]; then
    continue
  fi
  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    printf '::add-mask::%s\n' "${value}"
  fi
  if [[ "${value}" =~ ${credential_pattern} ]]; then
    echo "::error::${name} appears to contain credential material. Public CI must use credential-free mirrors/caches."
    exit 1
  fi
done

echo "[ci-log-input-guard] ok"
