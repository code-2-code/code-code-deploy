# Kubernetes validation schemas

Local JSON schemas used by `make -C deploy validate` and `validate-all` when public kubeconform catalogs do not publish a schema for a CRD we render.

CI validation does not fetch remote schema catalogs by default. If a local
environment needs an extra catalog, set `KUBECONFORM_REMOTE_SCHEMA_LOCATIONS`
outside the repository.

## Kiali

`kiali.io/kiali_v1alpha1.json` is generated from the official Kiali Operator CRD:

```bash
mkdir -p deploy/schemas/kiali.io
cd deploy/schemas/kiali.io
FILENAME_FORMAT='{kind}_{version}' \
  python3 "$(go env GOPATH)/pkg/mod/github.com/yannh/kubeconform@v0.7.0/scripts/openapi2jsonschema.py" \
  https://raw.githubusercontent.com/kiali/kiali-operator/master/crd-docs/crd/kiali.io_kialis.yaml
```
