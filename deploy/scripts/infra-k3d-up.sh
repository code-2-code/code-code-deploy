#!/usr/bin/env bash
set -euo pipefail

k3d_bin="${K3D:-k3d}"
kubectl_bin="${KUBECTL:-kubectl}"

cluster="${INFRA_K3D_CLUSTER:-code-code-infra}"
k3s_image="${INFRA_K3D_K3S_IMAGE:-rancher/k3s:v1.35.3-k3s1}"
tools_image="${INFRA_K3D_TOOLS_IMAGE:-}"
loadbalancer_image="${INFRA_K3D_LOADBALANCER_IMAGE:-}"
api_host="${INFRA_K3D_API_HOST:-}"
api_port="${INFRA_K3D_API_PORT:-7443}"
http_port="${INFRA_K3D_HTTP_PORT:-28080}"
https_port="${INFRA_K3D_HTTPS_PORT:-28443}"
registry_create="${INFRA_K3D_REGISTRY_CREATE:-false}"
registry_name="${INFRA_K3D_REGISTRY_NAME:-code-code-infra-registry}"
registry_port="${INFRA_K3D_REGISTRY_PORT:-25000}"
registry_config="${INFRA_K3D_REGISTRY_CONFIG:-}"
server_memory="${INFRA_K3D_SERVER_MEMORY:-16g}"
timeout="${INFRA_K3D_TIMEOUT:-5m}"
kubeconfig="${INFRA_K3D_KUBECONFIG:-${HOME}/.kube/${cluster}.kubeconfig}"

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[infra-k3d-up] missing required tool: $1" >&2
    exit 1
  fi
}

detect_host_ip() {
  local ip
  ip="$(ip -o route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "src") { print $(i + 1); exit }}')"
  if [[ -z "${ip}" ]]; then
    ip="$(hostname -I 2>/dev/null | tr ' ' '\n' | awk '$1 !~ /^(127|169\\.254|172\\.(1[6-9]|2[0-9]|3[0-1])|10\\.|192\\.168\\.122\\.)/ { print; exit }')"
  fi
  if [[ -z "${ip}" ]]; then
    echo "[infra-k3d-up] INFRA_K3D_API_HOST is empty and host IP could not be detected" >&2
    exit 1
  fi
  printf '%s\n' "${ip}"
}

cluster_exists() {
  "${k3d_bin}" cluster list 2>/dev/null | awk -v name="${cluster}" 'NR > 1 && $1 == name { found = 1 } END { exit !found }'
}

require_tool docker
require_tool "${k3d_bin}"
require_tool "${kubectl_bin}"

if ! docker info >/dev/null 2>&1; then
  echo "[infra-k3d-up] docker daemon is not reachable" >&2
  exit 1
fi

if [[ -z "${api_host}" ]]; then
  api_host="$(detect_host_ip)"
fi

if cluster_exists; then
  echo "[infra-k3d-up] cluster ${cluster} already exists; leaving it unchanged"
else
  if [[ -n "${tools_image}" ]]; then
    export K3D_IMAGE_TOOLS="${tools_image}"
  fi
  if [[ -n "${loadbalancer_image}" ]]; then
    export K3D_IMAGE_LOADBALANCER="${loadbalancer_image}"
  fi
  create_args=(
    cluster create "${cluster}"
    --servers 1
    --agents 0
    --image "${k3s_image}"
    --api-port "${api_host}:${api_port}"
    --servers-memory "${server_memory}"
    --timeout "${timeout}"
    --wait
    --port "${api_host}:${http_port}:80@loadbalancer"
    --port "${api_host}:${https_port}:443@loadbalancer"
    --k3s-arg "--disable=traefik@server:*"
    --k3s-arg "--disable=servicelb@server:*"
    --k3s-arg "--write-kubeconfig-mode=644@server:*"
  )
  if [[ "${registry_create}" == "true" ]]; then
    create_args+=(--registry-create "${registry_name}:${api_host}:${registry_port}")
  fi
  if [[ -n "${registry_config}" ]]; then
    create_args+=(--registry-config "${registry_config}")
  fi
  "${k3d_bin}" "${create_args[@]}"
fi

mkdir -p "$(dirname "${kubeconfig}")"
"${k3d_bin}" kubeconfig get "${cluster}" > "${kubeconfig}"
chmod 600 "${kubeconfig}"

echo "[infra-k3d-up] kubeconfig=${kubeconfig}"
KUBECONFIG="${kubeconfig}" "${kubectl_bin}" get nodes -o wide
