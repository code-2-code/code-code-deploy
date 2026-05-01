# code-code-deploy

Deployment assets for the Code Code platform.

This repository owns:

- `deploy/charts`: Helm charts and values.
- `deploy/images`: image build definitions and runtime Dockerfiles.
- `deploy/agents`: agent runtime image assets and sidecars.
- `deploy/scripts`: deployment and smoke-test scripts.

Image builds now consume the split source repositories as explicit Docker
Buildx Bake contexts. The default local layout is the `code-code-workspace`
checkout, where this repository sits next to repositories such as
`code-code-platform-auth-network`, `code-code-console-api`, and
`code-code-console-web`. Override the `*_CONTEXT` Make variables when building
from a different checkout layout.

Useful checks:

```bash
cd deploy && make lint
cd deploy && make template
cd deploy && make scripts-check
cd deploy && make bake-print
```

Single-host infra isolation:

```bash
cd deploy && make infra-k3d-up
cd deploy && make infra-k3d-status
```

`infra-k3d-up` creates a separate K3s control plane in Docker using k3d,
publishing the API on `7443`, HTTP on `28080`, and HTTPS on `28443` by
default. It is intended for internal infrastructure workloads such as GitLab,
CI runners, registry, and package caches without sharing the business cluster
API surface.

Keep regional image mirrors and helper-image overrides in `deploy/.env` or the
shell environment. Do not commit those operational choices into source values.

CI runs the same static deploy checks on pull requests and pushes to `main`:
script syntax, deploy-owned sidecar tests, Helm lint/template/validate, and
Buildx Bake checks against the split source repository contexts.
