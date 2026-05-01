# syntax=docker/dockerfile:1

ARG NODE_SLIM_BASE_IMAGE=node:24-bookworm-slim

FROM ${NODE_SLIM_BASE_IMAGE}

ARG NPM_CONFIG_REGISTRY
ARG CLI_PACKAGE
ARG CLI_VERSION
ARG AGENT_DIR
ARG OCI_SOURCE=""
ARG OCI_REVISION=""
ARG OCI_VERSION=""

ENV NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FUND=false

LABEL org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.version="${OCI_VERSION}"

RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    test -n "${CLI_PACKAGE}" && test -n "${CLI_VERSION}" && test -n "${AGENT_DIR}"; \
    if [ -n "${NPM_CONFIG_REGISTRY}" ]; then npm config set registry "${NPM_CONFIG_REGISTRY}"; fi; \
    npm install -g "${CLI_PACKAGE}@${CLI_VERSION}"

WORKDIR /workspace

COPY deploy/agents/common /usr/local/lib/code-code-agent/common
COPY deploy/agents/${AGENT_DIR} /usr/local/lib/${AGENT_DIR}

RUN install -m 0755 /usr/local/lib/${AGENT_DIR}/entrypoint.sh /usr/local/bin/agent-entrypoint.sh \
    && install -m 0755 /usr/local/lib/${AGENT_DIR}/prepare.sh /usr/local/bin/agent-prepare.sh \
    && install -m 0755 /usr/local/lib/code-code-agent/common/cli-output-runtime.sh /usr/local/bin/cli-output-runtime.sh \
    && install -m 0755 /usr/local/lib/code-code-agent/common/auth-helper.sh /usr/local/bin/claude-auth-helper.sh \
    && chown -R node:node /workspace

USER node

ENTRYPOINT ["/usr/local/bin/agent-entrypoint.sh"]
