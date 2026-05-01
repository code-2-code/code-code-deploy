# Agent Rules

- This repository owns deployment assets, Helm charts, image definitions, and deployment scripts.
- Do not edit platform, console, or contract source here.
- If a chart needs a new service contract or runtime behavior, make that change in the owning source repository first.
- Keep environment-specific values in ignored env files. Do not commit secrets or machine-local settings.
- Prefer validating charts and scripts before changing deployment behavior.
