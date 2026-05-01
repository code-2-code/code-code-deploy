#!/usr/bin/env bash
set -euo pipefail

k3d_bin="${K3D:-k3d}"
kubectl_bin="${KUBECTL:-kubectl}"
cluster="${INFRA_K3D_CLUSTER:-code-code-infra}"
kubeconfig="${INFRA_K3D_KUBECONFIG:-${HOME}/.kube/${cluster}.kubeconfig}"

if ! command -v "${k3d_bin}" >/dev/null 2>&1; then
  echo "[infra-k3d-status] missing required tool: ${k3d_bin}" >&2
  exit 1
fi

"${k3d_bin}" cluster list
"${k3d_bin}" node list | awk -v prefix="k3d-${cluster}" 'NR == 1 || index($1, prefix) == 1'

if [[ -f "${kubeconfig}" ]]; then
  KUBECONFIG="${kubeconfig}" "${kubectl_bin}" get nodes -o wide
  KUBECONFIG="${kubeconfig}" "${kubectl_bin}" get ns
else
  echo "[infra-k3d-status] kubeconfig not found: ${kubeconfig}" >&2
fi

