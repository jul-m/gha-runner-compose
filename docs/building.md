# Advanced Build Guide

This document covers advanced build topics for `gha-runner-compose` images. For basic usage and quick start instructions, see the [README](../README.md).

---

## Table of Contents
- [Advanced Build Guide](#advanced-build-guide)
  - [Table of Contents](#table-of-contents)
  - [Advanced BuildKit Configuration](#advanced-buildkit-configuration)
  - [Increase GitHub API Rate Limits During Build](#increase-github-api-rate-limits-during-build)
    - [With `docker buildx build`](#with-docker-buildx-build)
    - [With Docker Compose](#with-docker-compose)
  - [Multi-Architecture Builds](#multi-architecture-builds)
  - [Building All Image Tiers](#building-all-image-tiers)
    - [Base Image](#base-image)
    - [Essentials Image](#essentials-image)
    - [Category Images](#category-images)
    - [Aggregate Images (medium → all)](#aggregate-images-medium--all)
  - [Docker Maintenance](#docker-maintenance)
    - [Inspect Docker Disk Usage](#inspect-docker-disk-usage)
    - [Clean Build Cache](#clean-build-cache)
    - [Git Submodule](#git-submodule)

---

## Advanced BuildKit Configuration

To optimize multiple builds, create a dedicated BuildKit builder that leverages a persistent download cache. The provided `tools/buildkitd.toml` configures cache size limits (50 GB total, 25 GB for exec cache mounts).

1.  **Create the dedicated builder:**
    ```bash
    docker buildx create --driver docker-container \
        --name gha-runner-compose-builder --config ./tools/buildkitd.toml
    ```

2.  **Build with this builder:**
    ```bash
    docker buildx build \
        --build-arg RUNNER_COMPONENTS=java-tools,yq,docker \
        --target runner-build --progress=plain \
        --builder gha-runner-compose-builder --load \
        -t my-gha-runner:latest .
    ```
    The `--load` option is necessary to load the image into the local Docker engine (required when using a `docker-container` driver).

3.  **Remove the builder when no longer needed:**
    ```bash
    docker buildx rm gha-runner-compose-builder
    ```

---

## Increase GitHub API Rate Limits During Build

Some upstream scripts download assets from GitHub (releases, raw files, API metadata). Anonymous requests are heavily rate-limited. You can optionally provide a GitHub token (classic PAT or a fine-grained token with public repo scope) **without baking it into the image layers** by using a BuildKit secret. The custom `curl`/`wget` wrappers automatically add an `Authorization: Bearer` header for GitHub domains when `GITHUB_TOKEN` is available.

### With `docker buildx build`

1. Provide the token to BuildKit via an environment variable **or** a file:
    ```bash
    # Option A: environment variable
    export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxx

    # Option B: store it in a file
    echo "ghp_xxxxxxxxxxxxxxxxxxxxx" > ~/.config/github-token
    ```
2. Pass it as a secret when building:
    ```bash
    # Option A: from environment
    docker buildx build \
        --secret id=GITHUB_TOKEN,env=GITHUB_TOKEN \
        --build-arg RUNNER_COMPONENTS=yq,docker,java-tools \
        --target runner-build -t my-runner:latest .

    # Option B: from file
    docker buildx build \
        --secret id=GITHUB_TOKEN,src=$HOME/.config/github-token \
        --build-arg RUNNER_COMPONENTS=yq,docker,java-tools \
        --target runner-build -t my-runner:latest .
    ```

### With Docker Compose

Add a `secrets` section to your compose file:
```yaml
build:
    context: .
    target: runner-build
    secrets:
        - GITHUB_TOKEN
secrets:
    GITHUB_TOKEN:
        environment: GITHUB_TOKEN  # or: file: ~/.config/github-token
```

Nothing is persisted in the final image: the secret is exposed only inside each `RUN` layer where it is mounted. If you omit the secret entirely, builds fall back to anonymous requests (previous behavior).

> [!NOTE]
> The wrappers automatically look for `GITHUB_TOKEN` in the environment **and** inside `/run/secrets/GITHUB_TOKEN`. They purposely skip injection if you already set an explicit `Authorization` header in your build commands, or if the target URL is not a GitHub domain (`github.com`, `api.github.com`, `raw.githubusercontent.com`, `objects.githubusercontent.com`).

---

## Multi-Architecture Builds

To build for both AMD64 and ARM64 simultaneously, use the `--platform` flag. This requires a buildx builder with multi-architecture support (e.g., the dedicated builder created above, or the default `docker-container` driver).

```bash
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --build-arg RUNNER_COMPONENTS=java-tools,yq,docker \
    --target runner-build \
    -t my-gha-runner:latest .
```

> [!NOTE]
> When building for multiple platforms simultaneously, `--load` is not supported. Use `--push` to push to a registry, or build each platform separately with `--load`.

Some components are not available on ARM64 (see the ARM64 column in [components.md](./components.md)). The build system automatically handles architecture-specific overrides via scripts in `docker-build/components/`.

---

## Building All Image Tiers

This section provides the commands to build the full set of image tiers as published to the container registry. This is useful for maintainers or for reproducing the exact published images locally.

All examples below use shell variables for image naming:

```bash
BASE_IMAGE_NAME='ghcr.io/jul-m/gha-runner-compose-base:u24.04'
RUNNER_IMAGE_NAME='ghcr.io/jul-m/gha-runner-compose:u24.04'
TAG_SUFFIX='250401'    # date-based tag suffix (YYMMDD)
```

### Base Image

```bash
docker buildx build \
    --target base \
    -t "${BASE_IMAGE_NAME}-${TAG_SUFFIX}" .
```

### Essentials Image

```bash
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${BASE_IMAGE_NAME}-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-essentials \
    -t "${RUNNER_IMAGE_NAME}-essentials-${TAG_SUFFIX}" .
```

### Category Images

Each category image is built on top of `essentials`:

```bash
# Node.js
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-essentials-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-nodejs \
    -t "${RUNNER_IMAGE_NAME}-nodejs-${TAG_SUFFIX}" .

# Cloud
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-essentials-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-cloud \
    -t "${RUNNER_IMAGE_NAME}-cloud-${TAG_SUFFIX}" .

# Java
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-essentials-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-java \
    -t "${RUNNER_IMAGE_NAME}-java-${TAG_SUFFIX}" .

# Container
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-essentials-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-container \
    -t "${RUNNER_IMAGE_NAME}-container-${TAG_SUFFIX}" .

# Python
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-essentials-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-python \
    -t "${RUNNER_IMAGE_NAME}-python-${TAG_SUFFIX}" .

# .NET
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-essentials-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-dotnet \
    -t "${RUNNER_IMAGE_NAME}-dotnet-${TAG_SUFFIX}" .

# Build Tools
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-essentials-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-build \
    -t "${RUNNER_IMAGE_NAME}-build-${TAG_SUFFIX}" .
```

Category images are independent of each other and can be built in parallel.

### Aggregate Images (medium → all)

Aggregate images are built incrementally, each layer adding components on top of the previous one:

```bash
# Medium (based on build)
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-build-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-cloud,all-nodejs,all-java,all-container,all-python,all-rust \
    -t "${RUNNER_IMAGE_NAME}-medium-${TAG_SUFFIX}" .

# Large (based on medium)
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-medium-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-dotnet,all-php,all-ruby,all-r,all-julia,pipx-packages,all-web,all-databases \
    -t "${RUNNER_IMAGE_NAME}-large-${TAG_SUFFIX}" .

# X-Large (based on large)
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-large-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all-swift,actions-cache,codeql-bundle,firefox,selenium \
    -t "${RUNNER_IMAGE_NAME}-xlarge-${TAG_SUFFIX}" .

# All (based on xlarge)
docker buildx build --target runner-build \
    --build-arg BASE_IMAGE="${RUNNER_IMAGE_NAME}-xlarge-${TAG_SUFFIX}" \
    --build-arg RUNNER_COMPONENTS=all \
    -t "${RUNNER_IMAGE_NAME}-all-${TAG_SUFFIX}" .
```

For multi-architecture builds of the full tier chain, add `--platform linux/amd64,linux/arm64` and replace `--load` with `--push` (or build each platform separately).

> [!TIP]
> For complete image sizing and content details, see [docs/images.md](./images.md).

---

## Docker Maintenance

Useful commands for monitoring and cleaning up Docker resources used by the build process.

### Inspect Docker Disk Usage

```bash
# Show image tree (sizes and layers)
docker images --tree

# Show detailed disk usage (images, containers, volumes, build cache)
docker system df -v
```

### Clean Build Cache

```bash
# Clean regular build cache but keep BuildKit cache mounts (download caches)
docker buildx prune --filter 'type=regular' -f

# Clean ALL build cache (including cache mounts)
docker buildx prune --all -f
```

### Git Submodule

If you work with the `runner-images-src/` submodule, enable auto-update on pull/checkout:

```bash
git config submodule.recurse true
```
