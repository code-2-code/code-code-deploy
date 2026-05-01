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
