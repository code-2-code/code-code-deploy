# Upstream chart values overlays

Values files used to install upstream Helm charts.

Current tested upstream baseline:

- Istio Ambient: `1.29.2` (`base`, `istiod`, `cni`, `ztunnel` official charts)
- Gateway API CRDs: `v1.4.0` Experimental channel, bundled in `deploy/charts/cluster-bootstrap/crds`

Istio 1.29 is officially supported on Kubernetes 1.31-1.35. Its current
official Gateway API tasks and Ambient Helm install docs use Gateway API
`v1.4.0` Experimental-channel CRDs; Istio 1.29.2 ignores `TLSRoute` CRD
versions `v1.5+`.
`deploy/values/istiod.yaml` enables `PILOT_ENABLE_ALPHA_GATEWAY_API` because
Istio 1.29 requires it for Gateway API `TLSRoute` egress listeners.

Istio 1.30 migration note:

- Keep this repo on Istio 1.29.2 and Gateway API CRDs `v1.4.0` until Istio
  1.30 is an officially supported stable release.
- Istio upstream PR
  [#59299](https://github.com/istio/istio/pull/59299) moved Gateway API to
  `v1.5.x` and `TLSRoute` to `gateway.networking.k8s.io/v1` on master, which
  is the required upstream basis for removing `PILOT_ENABLE_ALPHA_GATEWAY_API`
  from this repo's TLSRoute egress path.
- Do not upgrade this repo to Gateway API `v1.4.1+` or `v1.5+` on Istio
  1.29.x. Upstream issue
  [#59949](https://github.com/istio/istio/issues/59949) tracks TLSRoute watcher
  breakage with Istio 1.29.2 and Gateway API `v1.4.1`.
- Do not migrate production egress to Istio 1.30 preliminary builds. Upstream
  issue [#59387](https://github.com/istio/istio/issues/59387) and the Istio
  preliminary feature status show this area is still settling.
- When Istio 1.30 is stable, migrate as one mainline change: install the
  official Gateway API CRDs required by that stable Istio release, change local
  generated `TLSRoute` resources to `gateway.networking.k8s.io/v1`, remove
  `PILOT_ENABLE_ALPHA_GATEWAY_API`, and verify `istioctl analyze`, Gateway
  conditions, waypoint status, and the preset-proxy egress smoke path.

Apply Gateway API CRDs with Kubernetes server-side apply:

```bash
make -C deploy gateway-api-crds-apply
```

| File | Upstream chart | Install |
| ---- | -------------- | ------- |
| `istiod.yaml` | [istio/istiod](https://istio.io/latest/docs/ambient/install/helm/) | `helm repo add istio https://istio-release.storage.googleapis.com/charts`<br>`helm upgrade --install istio-base istio/base --version 1.29.2 -n istio-system --create-namespace --wait`<br>`helm upgrade --install istiod istio/istiod --version 1.29.2 -n istio-system -f deploy/values/istiod.yaml --wait`<br>`helm upgrade --install istio-cni istio/cni --version 1.29.2 -n istio-system --wait`<br>`helm upgrade --install ztunnel istio/ztunnel --version 1.29.2 -n istio-system --wait` |
| `temporal.yaml` | [temporalio/temporal](https://github.com/temporalio/helm-charts) | `helm repo add temporalio https://go.temporal.io/helm-charts`<br>`helm install temporal temporalio/temporal -n code-code-infra -f deploy/values/temporal.yaml --create-namespace` |

Pre-create the `postgres-auth` Secret in `code-code-infra` (with key `POSTGRES_PASSWORD`) before installing Temporal — its schema job and frontend both consume it.
