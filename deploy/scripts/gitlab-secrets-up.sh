#!/usr/bin/env bash
set -euo pipefail

kubectl_bin="${KUBECTL:-kubectl}"
namespace="${GITLAB_NAMESPACE:-gitlab}"

random_value() {
  local length="${1:-48}"
  local bytes=$(((length + 1) / 2))
  openssl rand -hex "${bytes}" | cut -c "1-${length}"
}

secret_value() {
  local secret="$1"
  local key="$2"
  if "${kubectl_bin}" -n "${namespace}" get secret "${secret}" >/dev/null 2>&1; then
    "${kubectl_bin}" -n "${namespace}" get secret "${secret}" -o jsonpath="{.data.${key}}" 2>/dev/null | base64 -d || true
  fi
}

ensure_literal_secret() {
  local secret="$1"
  local key="$2"
  local value
  value="$(secret_value "${secret}" "${key}")"
  if [[ -z "${value}" ]]; then
    value="$(random_value 64)"
  fi
  "${kubectl_bin}" -n "${namespace}" create secret generic "${secret}" \
    --from-literal="${key}=${value}" \
    --dry-run=client -o yaml | "${kubectl_bin}" apply -f - >/dev/null
}

"${kubectl_bin}" create namespace "${namespace}" --dry-run=client -o yaml | "${kubectl_bin}" apply -f - >/dev/null

ensure_literal_secret gitlab-initial-root-password password
ensure_literal_secret gitlab-postgresql-password postgres-password
ensure_literal_secret gitlab-valkey password

minio_user="$(secret_value gitlab-minio root-user)"
minio_password="$(secret_value gitlab-minio root-password)"
if [[ -z "${minio_user}" ]]; then
  minio_user="gitlab-minio"
fi
if [[ -z "${minio_password}" ]]; then
  minio_password="$(random_value 64)"
fi
"${kubectl_bin}" -n "${namespace}" create secret generic gitlab-minio \
  --from-literal=root-user="${minio_user}" \
  --from-literal=root-password="${minio_password}" \
  --dry-run=client -o yaml | "${kubectl_bin}" apply -f - >/dev/null

tmp_dir="$(mktemp -d /tmp/code-code-gitlab-secrets.XXXXXX)"
trap 'rm -rf "${tmp_dir}"' EXIT

cat >"${tmp_dir}/rails.minio.yaml" <<EOF
provider: AWS
region: us-east-1
aws_access_key_id: ${minio_user}
aws_secret_access_key: ${minio_password}
aws_signature_version: 4
host: gitlab-minio.gitlab.svc.cluster.local
endpoint: "http://gitlab-minio.gitlab.svc.cluster.local:9000"
path_style: true
EOF

cat >"${tmp_dir}/registry.minio.yaml" <<EOF
s3:
  v4auth: true
  regionendpoint: "http://gitlab-minio.gitlab.svc.cluster.local:9000"
  pathstyle: true
  region: us-east-1
  bucket: gitlab-registry-storage
  accesskey: ${minio_user}
  secretkey: ${minio_password}
EOF

"${kubectl_bin}" -n "${namespace}" create secret generic gitlab-object-storage \
  --from-file=connection="${tmp_dir}/rails.minio.yaml" \
  --dry-run=client -o yaml | "${kubectl_bin}" apply -f - >/dev/null

"${kubectl_bin}" -n "${namespace}" create secret generic gitlab-registry-storage \
  --from-file=config="${tmp_dir}/registry.minio.yaml" \
  --dry-run=client -o yaml | "${kubectl_bin}" apply -f - >/dev/null

echo "[gitlab-secrets-up] secrets are present in namespace ${namespace}"
