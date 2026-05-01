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
