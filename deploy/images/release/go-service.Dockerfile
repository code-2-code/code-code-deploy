# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM golang:1.26-bookworm AS build

ARG GOPROXY
ARG TARGETOS=linux
ARG TARGETARCH=amd64
ARG SERVICE_MODULE
ARG SERVICE_NAME
ARG OCI_SOURCE=""
ARG OCI_REVISION=""
ARG OCI_VERSION=""

ENV CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    GOFLAGS=-mod=readonly \
    GOPROXY=${GOPROXY}

WORKDIR /workspace/source/${SERVICE_MODULE}

RUN test -n "${SERVICE_MODULE}" && test -n "${SERVICE_NAME}"

COPY --from=source . /workspace/source

RUN --mount=type=cache,target=/go/pkg/mod,id=code-code-go-mod-cache,sharing=locked \
    go mod download

RUN --mount=type=cache,target=/go/pkg/mod,id=code-code-go-mod-cache,sharing=locked \
    --mount=type=cache,target=/root/.cache/go-build,id=code-code-go-build-cache,sharing=locked \
    go build -buildvcs=false -trimpath -ldflags="-s -w" -o /out/${SERVICE_NAME} ./cmd/${SERVICE_NAME}

FROM scratch

ARG EXPOSE_PORT=8081
ARG SERVICE_NAME
ARG OCI_SOURCE=""
ARG OCI_REVISION=""
ARG OCI_VERSION=""

ENV USER=nonroot

USER 65532:65532

LABEL org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.version="${OCI_VERSION}"

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /out/${SERVICE_NAME} /app

EXPOSE ${EXPOSE_PORT}

ENTRYPOINT ["/app"]
