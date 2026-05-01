# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM golang:1.26-bookworm AS build

ARG GOPROXY
ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG OCI_SOURCE=""
ARG OCI_REVISION=""
ARG OCI_VERSION=""

ENV CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    GOFLAGS=-mod=readonly \
    GOPROXY=${GOPROXY}

RUN test -n "${TARGETOS}" && test -n "${TARGETARCH}"

WORKDIR /workspace/code-code-deploy/deploy/agents/sidecars/cli-output

COPY deploy/agents/sidecars/cli-output/go.mod /workspace/code-code-deploy/deploy/agents/sidecars/cli-output/go.mod
COPY deploy/agents/sidecars/cli-output/go.sum /workspace/code-code-deploy/deploy/agents/sidecars/cli-output/go.sum
COPY code-code-contracts/packages/go-contract /workspace/code-code-deploy/code-code-contracts/packages/go-contract

RUN --mount=type=cache,target=/go/pkg/mod,id=code-code-cli-output-go-mod-cache,sharing=locked \
    --mount=type=cache,target=/root/.cache/go-build,id=code-code-cli-output-go-build-cache,sharing=locked \
    go mod download

COPY deploy/agents/sidecars/cli-output /workspace/code-code-deploy/deploy/agents/sidecars/cli-output

RUN --mount=type=cache,target=/go/pkg/mod,id=code-code-cli-output-go-mod-cache,sharing=locked \
    --mount=type=cache,target=/root/.cache/go-build,id=code-code-cli-output-go-build-cache,sharing=locked \
    go build -trimpath -ldflags="-s -w" -o /out/cli-output-sidecar ./cmd/cli-output-sidecar

FROM scratch

ARG OCI_SOURCE=""
ARG OCI_REVISION=""
ARG OCI_VERSION=""

USER 65532:65532

LABEL org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.version="${OCI_VERSION}"

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /out/cli-output-sidecar /cli-output-sidecar

ENTRYPOINT ["/cli-output-sidecar"]
