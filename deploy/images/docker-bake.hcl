// docker-bake.hcl — 多架构镜像构建定义。
// 见 deploy/Makefile（build/push/deploy 入口）。

variable "BUILD_NPM_REGISTRY" {
  default = ""
}

variable "BUILD_GOPROXY" {
  default = ""
}

variable "BUILD_PIP_INDEX_URL" {
  default = ""
}

variable "BUILD_DEBIAN_MIRROR" {
  default = ""
}

variable "IMAGE_REGISTRY" {
  default = ""
}

variable "IMAGE_TAG" {
  default = "0.0.0"
}

variable "IMAGE_REVISION" {
  default = ""
}

variable "SOURCE_URL_BASE" {
  default = "https://github.com/code-2-code"
}

variable "PLATFORM_AUTH_NETWORK_CONTEXT" {
  default = "../code-code-platform-auth-network"
}

variable "PLATFORM_CATALOG_CONTEXT" {
  default = "../code-code-platform-catalog"
}

variable "PLATFORM_PROVIDER_CONTEXT" {
  default = "../code-code-platform-provider"
}

variable "PLATFORM_PROFILE_CONTEXT" {
  default = "../code-code-platform-profile"
}

variable "PLATFORM_AGENT_RUNTIME_CONTEXT" {
  default = "../code-code-platform-agent-runtime"
}

variable "PLATFORM_NOTIFICATIONS_CONTEXT" {
  default = "../code-code-platform-notifications"
}

variable "CONSOLE_API_CONTEXT" {
  default = "../code-code-console-api"
}

variable "CONSOLE_WEB_CONTEXT" {
  default = "../code-code-console-web"
}

variable "SHOWCASE_API_CONTEXT" {
  default = "../code-code-showcase-api"
}

variable "DEFAULT_PLATFORMS" {
  default = "linux/amd64,linux/arm64"
}

variable "CLAUDE_CODE_CLI_VERSION" {
  default = "2.1.121"
}

variable "QWEN_CLI_VERSION" {
  default = "0.15.4"
}

variable "GEMINI_CLI_VERSION" {
  default = "0.39.1"
}

variable "GOST_IMAGE" {
  default = "gogost/gost:3.2.6"
}

# 包管理代理参数（所有可联网构建的 target 继承）。
target "_proxyable" {
  args = {
    BUILD_NPM_REGISTRY    = "${BUILD_NPM_REGISTRY}"
    NPM_CONFIG_REGISTRY   = "${BUILD_NPM_REGISTRY}"
    COREPACK_NPM_REGISTRY = "${BUILD_NPM_REGISTRY}"
    GOPROXY               = "${BUILD_GOPROXY}"
    PIP_INDEX_URL         = "${BUILD_PIP_INDEX_URL}"
    DEBIAN_MIRROR         = "${BUILD_DEBIAN_MIRROR}"
    OCI_SOURCE            = "${SOURCE_URL_BASE}/code-code-deploy"
    OCI_REVISION          = "${IMAGE_REVISION}"
    OCI_VERSION           = "${IMAGE_TAG}"
  }
}

# 多架构默认值。
target "_multiarch" {
  platforms = split(",", DEFAULT_PLATFORMS)
}

# --- Groups ---

# 默认构建：随 chart/platform 部署的所有镜像 + agent runtime + sidecar。
group "default" {
  targets = [
    "platform-auth-service",
    "platform-model-service",
    "platform-provider-service",
    "platform-provider-orchestration-service",
    "platform-egress-service",
    "platform-profile-service",
    "platform-support-service",
    "platform-cli-runtime-service",
    "platform-agent-runtime-service",
    "platform-chat-service",
    "platform-egress-forwarder",
    "console-api",
    "console-web",
    "showcase-api",
    "showcase-web",
    "claude-code-agent",
    "agent-cli-qwen",
    "agent-cli-gemini",
    "cli-output-sidecar",
  ]
}

# 平台后端和前端服务镜像集合。
group "platform" {
  targets = [
    "platform-auth-service",
    "platform-model-service",
    "platform-provider-service",
    "platform-provider-orchestration-service",
    "platform-egress-service",
    "platform-profile-service",
    "platform-support-service",
    "platform-cli-runtime-service",
    "platform-agent-runtime-service",
    "platform-chat-service",
    "platform-egress-forwarder",
    "console-api",
    "console-web",
    "showcase-api",
    "showcase-web",
  ]
}

# 仅 agent runtime 镜像。
group "runtime" {
  targets = [
    "claude-code-agent",
    "agent-cli-qwen",
    "agent-cli-gemini",
    "cli-output-sidecar",
  ]
}

# 可选服务：默认不构建，需显式 `bake notification-dispatcher` 或加入自定义 group。
group "optional" {
  targets = [
    "notification-dispatcher",
    "wecom-callback-adapter",
  ]
}

# --- Go services ---

target "_go_service" {
  inherits   = ["_proxyable", "_multiarch"]
  context    = "."
  dockerfile = "deploy/images/release/go-service.Dockerfile"
}

target "_go_auth_network_service" {
  inherits = ["_go_service"]
  contexts = {
    source = "${PLATFORM_AUTH_NETWORK_CONTEXT}"
  }
  args = {
    SERVICE_MODULE = "packages/platform-k8s"
    OCI_SOURCE     = "${SOURCE_URL_BASE}/code-code-platform-auth-network"
  }
}

target "_go_catalog_service" {
  inherits = ["_go_service"]
  contexts = {
    source = "${PLATFORM_CATALOG_CONTEXT}"
  }
  args = {
    SERVICE_MODULE = "packages/platform-k8s"
    OCI_SOURCE     = "${SOURCE_URL_BASE}/code-code-platform-catalog"
  }
}

target "_go_provider_service" {
  inherits = ["_go_service"]
  contexts = {
    source = "${PLATFORM_PROVIDER_CONTEXT}"
  }
  args = {
    SERVICE_MODULE = "packages/platform-k8s"
    OCI_SOURCE     = "${SOURCE_URL_BASE}/code-code-platform-provider"
  }
}

target "_go_profile_service" {
  inherits = ["_go_service"]
  contexts = {
    source = "${PLATFORM_PROFILE_CONTEXT}"
  }
  args = {
    SERVICE_MODULE = "packages/platform-k8s"
    OCI_SOURCE     = "${SOURCE_URL_BASE}/code-code-platform-profile"
  }
}

target "_go_agent_runtime_service" {
  inherits = ["_go_service"]
  contexts = {
    source = "${PLATFORM_AGENT_RUNTIME_CONTEXT}"
  }
  args = {
    SERVICE_MODULE = "packages/platform-k8s"
    OCI_SOURCE     = "${SOURCE_URL_BASE}/code-code-platform-agent-runtime"
  }
}

target "_go_notifications_service" {
  inherits = ["_go_service"]
  contexts = {
    source = "${PLATFORM_NOTIFICATIONS_CONTEXT}"
  }
  args = {
    SERVICE_MODULE = "packages/platform-k8s"
    OCI_SOURCE     = "${SOURCE_URL_BASE}/code-code-platform-notifications"
  }
}

target "_go_console_service" {
  inherits = ["_go_service"]
  contexts = {
    source = "${CONSOLE_API_CONTEXT}"
  }
  args = {
    SERVICE_MODULE = "packages/console-api"
    OCI_SOURCE     = "${SOURCE_URL_BASE}/code-code-console-api"
  }
}

target "_go_showcase_service" {
  inherits = ["_go_service"]
  contexts = {
    source = "${SHOWCASE_API_CONTEXT}"
  }
  args = {
    SERVICE_MODULE = "packages/showcase-api"
    OCI_SOURCE     = "${SOURCE_URL_BASE}/code-code-showcase-api"
  }
}

target "platform-auth-service" {
  inherits = ["_go_auth_network_service"]
  args     = { SERVICE_NAME = "platform-auth-service" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-auth-service:${IMAGE_TAG}"]
}

target "platform-model-service" {
  inherits = ["_go_catalog_service"]
  args     = { SERVICE_NAME = "platform-model-service" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-model-service:${IMAGE_TAG}"]
}

target "platform-provider-service" {
  inherits = ["_go_provider_service"]
  args     = { SERVICE_NAME = "platform-provider-service" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-provider-service:${IMAGE_TAG}"]
}

target "platform-provider-orchestration-service" {
  inherits = ["_go_provider_service"]
  args     = { SERVICE_NAME = "platform-provider-orchestration-service" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-provider-orchestration-service:${IMAGE_TAG}"]
}

target "platform-egress-service" {
  inherits = ["_go_auth_network_service"]
  args     = { SERVICE_NAME = "platform-egress-service" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-egress-service:${IMAGE_TAG}"]
}

target "platform-egress-forwarder" {
  inherits   = ["_proxyable", "_multiarch"]
  context    = "."
  dockerfile = "deploy/images/release/gost-forwarder.Dockerfile"
  args       = { GOST_IMAGE = "${GOST_IMAGE}" }
  tags       = ["${IMAGE_REGISTRY}code-code/platform-egress-forwarder:${IMAGE_TAG}"]
}

target "platform-profile-service" {
  inherits = ["_go_profile_service"]
  args     = { SERVICE_NAME = "platform-profile-service" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-profile-service:${IMAGE_TAG}"]
}

target "platform-support-service" {
  inherits = ["_go_catalog_service"]
  args     = { SERVICE_NAME = "platform-support-service", EXPOSE_PORT = "8080" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-support-service:${IMAGE_TAG}"]
}

target "platform-cli-runtime-service" {
  inherits = ["_go_catalog_service"]
  args     = { SERVICE_NAME = "platform-cli-runtime-service", EXPOSE_PORT = "8080" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-cli-runtime-service:${IMAGE_TAG}"]
}

target "platform-agent-runtime-service" {
  inherits = ["_go_agent_runtime_service"]
  args     = { SERVICE_NAME = "platform-agent-runtime-service" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-agent-runtime-service:${IMAGE_TAG}"]
}

target "notification-dispatcher" {
  inherits = ["_go_notifications_service"]
  args     = { SERVICE_NAME = "notification-dispatcher", EXPOSE_PORT = "8080" }
  tags     = ["${IMAGE_REGISTRY}code-code/notification-dispatcher:${IMAGE_TAG}"]
}

target "wecom-callback-adapter" {
  inherits = ["_go_notifications_service"]
  args     = { SERVICE_NAME = "wecom-callback-adapter", EXPOSE_PORT = "8080" }
  tags     = ["${IMAGE_REGISTRY}code-code/wecom-callback-adapter:${IMAGE_TAG}"]
}

# --- Console & Chat ---

target "platform-chat-service" {
  inherits = ["_go_console_service"]
  args     = { SERVICE_NAME = "platform-chat-service" }
  tags     = ["${IMAGE_REGISTRY}code-code/platform-chat-service:${IMAGE_TAG}"]
}

target "console-api" {
  inherits = ["_go_console_service"]
  args     = { SERVICE_NAME = "console-api", EXPOSE_PORT = "8080" }
  tags     = ["${IMAGE_REGISTRY}code-code/console-api:${IMAGE_TAG}"]
}

target "console-web" {
  inherits   = ["_proxyable", "_multiarch"]
  context    = "."
  dockerfile = "deploy/images/release/web-static.Dockerfile"
  contexts = {
    source = "${CONSOLE_WEB_CONTEXT}"
  }
  args = {
    WEB_FILTER   = "@code-code/console-web-app..."
    WEB_DIST     = "app/dist"
    NGINX_CONFIG = "console-web.nginx.conf"
    OCI_SOURCE   = "${SOURCE_URL_BASE}/code-code-console-web"
  }
  tags       = ["${IMAGE_REGISTRY}code-code/console-web:${IMAGE_TAG}"]
}

target "showcase-api" {
  inherits = ["_go_showcase_service"]
  args     = { SERVICE_NAME = "showcase-api", EXPOSE_PORT = "8080" }
  tags     = ["${IMAGE_REGISTRY}code-code/showcase-api:${IMAGE_TAG}"]
}

target "showcase-web" {
  inherits   = ["_proxyable", "_multiarch"]
  context    = "."
  dockerfile = "deploy/images/release/web-static.Dockerfile"
  contexts = {
    source = "${CONSOLE_WEB_CONTEXT}"
  }
  args = {
    WEB_FILTER   = "@code-code/showcase-web..."
    WEB_DIST     = "showcase/dist"
    NGINX_CONFIG = "showcase-web.nginx.conf"
    OCI_SOURCE   = "${SOURCE_URL_BASE}/code-code-console-web"
  }
  tags       = ["${IMAGE_REGISTRY}code-code/showcase-web:${IMAGE_TAG}"]
}

# --- Agent runtimes ---

target "claude-code-agent" {
  inherits   = ["_proxyable", "_multiarch"]
  context    = "."
  dockerfile = "deploy/images/release/node-cli-agent.Dockerfile"
  args = {
    AGENT_DIR   = "claude-code"
    CLI_PACKAGE = "@anthropic-ai/claude-code"
    CLI_VERSION = "${CLAUDE_CODE_CLI_VERSION}"
  }
  tags       = ["${IMAGE_REGISTRY}code-code/claude-code-agent:${IMAGE_TAG}"]
}

target "agent-cli-qwen" {
  inherits   = ["_proxyable", "_multiarch"]
  context    = "."
  dockerfile = "deploy/images/release/node-cli-agent.Dockerfile"
  args = {
    AGENT_DIR   = "qwen-cli"
    CLI_PACKAGE = "@qwen-code/qwen-code"
    CLI_VERSION = "${QWEN_CLI_VERSION}"
  }
  tags       = ["${IMAGE_REGISTRY}code-code/agent-cli-qwen:${IMAGE_TAG}"]
}

target "agent-cli-gemini" {
  inherits   = ["_proxyable", "_multiarch"]
  context    = "."
  dockerfile = "deploy/images/release/node-cli-agent.Dockerfile"
  args = {
    AGENT_DIR   = "gemini-cli"
    CLI_PACKAGE = "@google/gemini-cli"
    CLI_VERSION = "${GEMINI_CLI_VERSION}"
  }
  tags       = ["${IMAGE_REGISTRY}code-code/agent-cli-gemini:${IMAGE_TAG}"]
}

# --- Sidecars ---

target "cli-output-sidecar" {
  inherits   = ["_proxyable", "_multiarch"]
  context    = "."
  dockerfile = "deploy/images/release/cli-output-sidecar.Dockerfile"
  tags       = ["${IMAGE_REGISTRY}code-code/cli-output-sidecar:${IMAGE_TAG}"]
}
