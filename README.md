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

Keep regional image mirrors and helper-image overrides in `deploy/.env` or the
shell environment. Do not commit those operational choices into source values.

Image registries, pull-through caches, and package mirrors are external
infrastructure prerequisites. This repository consumes them through
`IMAGE_REGISTRY`, k3d/containerd mirror configuration, or ignored local env
files; it does not deploy or own registry/cache services.

Self-hosted GitLab, bootstrap infra cluster, GitLab project catalog, and
internal CI runner infrastructure live in the separate GitLab repository
`code-2-code/self-hosted-infra`.

External GitHub CI is intentionally not configured. Run static deploy checks
locally for now; internal GitLab CI/CD should be added separately with GitLab
Runner after the repositories are migrated.
