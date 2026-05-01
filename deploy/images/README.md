# Deployment images

## Responsibility

Owns container image build definitions for platform services, agent runtimes, and sidecars.

## Layout

- `docker-bake.hcl` — single source of truth for all image targets and build groups (multi-arch, cache-aware).
- `release/` — release Dockerfiles consumed by `docker-bake.hcl`. Shared Dockerfiles are parameterized by Bake args instead of duplicated per target.

## Build groups

`docker-bake.hcl` defines four groups; use `deploy/Makefile` for build and deploy commands:

- `default` — every image installed by `charts/platform` plus agent runtimes and sidecars.
- `platform` — platform backend and frontend service images.
- `runtime` — only agent runtime images (`claude-code-agent`, `agent-cli-qwen`, `agent-cli-gemini`, `cli-output-sidecar`).
- `runner` — the ARC self-hosted runner image with pre-populated GitHub tool cache.
- `optional` — `notification-dispatcher`, `wecom-callback-adapter`. Not built by default.

## Agent CLI versions

Release agent images do not install floating npm `latest` versions. The current validated defaults are:

- `CLAUDE_CODE_CLI_VERSION=2.1.121`
- `QWEN_CLI_VERSION=0.15.4`
- `GEMINI_CLI_VERSION=0.39.1`

Override these through `deploy/Makefile` or the buildx bake environment when intentionally testing a newer CLI.

## Go service images

- `platform-auth-service`, `platform-egress-service` — `code-code-platform-auth-network` context.
- `platform-model-service`, `platform-support-service`, `platform-cli-runtime-service` — `code-code-platform-catalog` context.
- `platform-provider-service`, `platform-provider-orchestration-service` — `code-code-platform-provider` context.
- `platform-profile-service` — `code-code-platform-profile` context.
- `platform-agent-runtime-service` — `code-code-platform-agent-runtime` context.
- `platform-chat-service`, `console-api` — `code-code-console-api` context.
- `showcase-api` — `code-code-showcase-api` context.
- `notification-dispatcher`, `wecom-callback-adapter` — `code-code-platform-notifications` context, opt-in via the `optional` group.

Each Go image still uses `release/go-service.Dockerfile`; Bake binds the right
source repository to the Dockerfile as the named `source` context.

## Console / sidecar

- `console-web`, `showcase-web` — `code-code-console-web` context with `release/web-static.Dockerfile`, multi-stage pnpm + nginx-unprivileged.
- `cli-output-sidecar` — deploy-owned source under `deploy/agents/sidecars/cli-output/`, scratch base, and the `code-code-contracts` submodule for generated contracts.

## GitHub Actions runner

- `actions-runner-toolcache` — based on the official `ghcr.io/actions/actions-runner` image, with Go pre-populated under `/opt/hostedtoolcache` for `actions/setup-go`, plus `make` and `helm`.
- The runner image does not contain proxy credentials. Package mirrors and authenticated HTTP proxies are injected through ARC values or ignored Helm overrides.
- Go, npm, pip, and uv cache directories live under `/home/runner/.cache` so ARC can mount the deploy-owned runner cache PVC there. The runner pod sets `fsGroup: 1001` to keep that volume writable by the official `runner` user.
- Download points are explicit Bake args: base images, npm registry, Go proxy, pip index, runner Go download base plus fallback, runner Helm download base plus fallback, runner apt mirror, and the runner build-time third-party apt source toggle. Keep domestic mirror choices in `deploy/.env`, shell environment, or remote builder config; do not commit them into workflow files.

All release Dockerfiles set OCI image metadata from Bake args. Use
`IMAGE_REVISION=<commit>` when CI knows the source revision.

## Build commands

All build paths go through `deploy/Makefile`:

```bash
make -C deploy build BAKE_TARGET=default        # everything used by `make deploy`
make -C deploy build BAKE_TARGET=runtime        # only agent runtimes
IMAGE_REGISTRY=192.168.0.126:30500/ make -C deploy runner-image-push
make -C deploy push  BAKE_TARGET=platform IMAGE_REGISTRY=192.168.0.126:30500/
make -C deploy bake-print                       # dump resolved bake config
make -C deploy bake-check                       # Docker Buildx static checks
make -C deploy bake-check-remote                # run Buildx checks on REMOTE_DOCKER_HOST
```

`bake-check-remote` sends this deploy repository plus the split source contexts
needed for Buildx checks. Override `REMOTE_DOCKER_HOST` and
`REMOTE_BAKE_PLATFORM` when using a different builder host or platform.

For the end-to-end deploy flow, use the root `README.md` and `deploy/Makefile`.
