# Agent Rules

This repository owns deployment assets, Helm charts, image definitions, agent image assets, sidecars, and deployment scripts.

## Source Boundaries

- Do not edit platform, console, showcase, or contract source behavior here.
- Treat split source repositories as build inputs. Image definitions may reference them through explicit BuildKit/Bake contexts or checked-out submodules, but runtime code changes must land in the owning source repository first.
- If a chart needs a new service contract, event, API shape, persistence behavior, or runtime feature, make that change in the owning source repository before changing deploy wiring.
- Do not recreate the original monorepo layout in this repository. Avoid new references to old aggregate paths such as root-level `packages/*` unless the path is inside a declared source context.
- Keep environment-specific values in ignored env files or chart examples. Do not commit secrets, tokens, private keys, kubeconfigs, or machine-local settings.

## Official Baseline

Use these current official references before changing this repository:

- Kubernetes recommended labels and object labeling: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/
- Helm chart label conventions: https://helm.sh/docs/chart_best_practices/labels/
- Docker build best practices and build contexts: https://docs.docker.com/build/building/best-practices/ and https://docs.docker.com/build/concepts/context/
- Docker Buildx Bake additional contexts: https://docs.docker.com/build/bake/contexts/
- GitHub Actions least-privilege `GITHUB_TOKEN` permissions and reusable workflows: https://docs.github.com/en/actions/tutorials/authenticate-with-github_token and https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
- OCI image annotations: https://github.com/opencontainers/image-spec/blob/main/annotations.md

## Kubernetes And Helm

- Helm charts must use current stable Kubernetes API versions and Helm templates as the canonical deployment surface.
- Workloads, Services, routes, policies, and generated manifests must carry consistent `app.kubernetes.io/*` labels. Prefer `name`, `instance`, `component`, `part-of`, `managed-by`, and `version` where applicable.
- Selectors must be stable and unambiguous. Do not reuse labels in ways that confuse ownership, routing, policy, or rollout selection.
- New chart values must be documented by `values.schema.json` when the chart already has one, and by chart README generation when values tables are updated.
- Keep desired state in `spec` and runtime observation in `status`; do not encode behavior scripts or domain models in YAML.

## Image Builds

- Each application image must build from its owning split source repository context. Deploy-owned images may build from this repository and checked-out submodules.
- Shared Dockerfiles must stay parameterized by service identity and source context, not by behavior flags or hidden compatibility modes.
- Prefer multi-stage Dockerfiles, small runtime bases, `.dockerignore`, non-root runtime users, explicit ports, and BuildKit cache mounts where useful.
- Do not pass secrets through Docker build args, labels, environment variables, logs, or image layers.
- Images should carry OCI metadata when CI provides it: `org.opencontainers.image.source`, `org.opencontainers.image.revision`, and `org.opencontainers.image.version`.
- Tags consumed by charts should be immutable release tags, commit SHAs, or digests. Do not rely on floating `latest`.

## CI And Verification

- If GitHub Actions are added here, use least-privilege `permissions`, explicit repository or path inputs, and reusable workflows for repeated image build logic.
- Public CI logs must not echo environment-derived values or Helm/BuildKit argument strings. Suppress Make command echo for targets that pass registry, mirror, proxy, token, or credential-adjacent values, and run the CI log input guard before build checks.
- If self-hosted GitHub Actions runners are added, use the official Actions Runner Controller `gha-runner-scale-set-controller` and `gha-runner-scale-set` Helm charts. Keep controller pods and runner pods in separate namespaces, pass GitHub credentials through Kubernetes Secret references, do not commit token material, and set bounded resources for controller, listener, and runner pods.
- The runner scale set name is the `runs-on` contract. Change it deliberately and update workflows in the same change.
- Keep source repositories and workflows network-agnostic. If GitHub connectivity is unstable, solve it at the runner/cluster egress layer or with deploy-owned package and image caches through ignored local env or Helm overrides; do not commit proxy URLs, proxy credentials, or region-specific mirror assumptions into source repositories or workflows.
- Validate deployment changes with the narrowest meaningful checks:
  - `make -C deploy lint-all`
  - `make -C deploy template-all`
  - `make -C deploy validate-all`
  - `make -C deploy scripts-check`
  - `make -C deploy bake-print`
  - `make -C deploy bake-check`
- Run `make -C deploy docs` after chart value documentation changes.
- Do not commit chart packages, local build contexts, generated temporary directories, `node_modules`, `dist`, coverage, or local cache output.
