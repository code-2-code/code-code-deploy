# code-code-deploy

Deployment assets for the Code Code platform.

This repository owns:

- `deploy/charts`: Helm charts and values.
- `deploy/images`: image build definitions and runtime Dockerfiles.
- `deploy/agents`: agent runtime image assets and sidecars.
- `deploy/scripts`: deployment and smoke-test scripts.

This split preserves source history from the original monorepo. The current
image build definitions still reflect the original monorepo context. The next
step is to make deploy consume built images and released artifacts from the
split source repositories.

Useful checks:

```bash
cd deploy && make lint
cd deploy && make template
cd deploy && make scripts-check
```
