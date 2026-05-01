#!/usr/bin/env bash
set -euo pipefail

k3d_bin="${K3D:-k3d}"
cluster="${INFRA_K3D_CLUSTER:-code-code-infra}"
confirm="${INFRA_K3D_CONFIRM_DELETE:-}"

if [[ "${confirm}" != "${cluster}" ]]; then
  echo "[infra-k3d-down] refusing to delete ${cluster}; set INFRA_K3D_CONFIRM_DELETE=${cluster}" >&2
  exit 1
fi

"${k3d_bin}" cluster delete "${cluster}"

