# Pre-Built Images

This document describes the project's pre-built Docker images; detailed explanations and usage notes are provided in the sections below.

All images are published for both AMD64 and ARM64 using the same image tags via multi-architecture (manifest) support. Pulling a tag will automatically return the correct architecture for your machine; to force a specific arch, use e.g. `docker pull --platform linux/amd64 <image>` or `docker pull --platform linux/arm64 <image>`.

## Quick reference — available images

The table below provides a compact overview of the main pre-built tags, what they are based on, a short content summary and approximate sizes. Use the `Full Reference` column to pull or reference the image directly.

| Short Name | Full Reference | Based on | Short contents | Approx. size (compressed / uncompressed) | Notes |
|---|---|---|---|---|---|
| **base** | `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest` | ubuntu:24.04 (base stage) | Minimal prerequisites, `runner` user, entrypoint | ~300 MB / ~1.25 GB | Use as `BASE_IMAGE` for custom builds |
| **essentials** | `ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest` | base | `all-essentials` (git, github-cli, yq, nodejs-lite, runner-package...) | ~800 MB / ~2.75 GB | Small image with basic tools |
| **nodejs** | `ghcr.io/jul-m/gha-runner-compose:u24.04-nodejs-latest` | essentials | `all-nodejs` | ~1 GB / ~4 GB | Thematic image for Node.js tooling |
| **cloud** | `ghcr.io/jul-m/gha-runner-compose:u24.04-cloud-latest` | essentials | `all-cloud` (aws, azure, gcloud CLIs, etc.) | ~1.5 GB / ~6.5 GB | Cloud CLIs and tools |
| **java** | `ghcr.io/jul-m/gha-runner-compose:u24.04-java-latest` | essentials | `all-java` | ~2 GB / ~6 GB | Java toolchains and SDKs |
| **container** | `ghcr.io/jul-m/gha-runner-compose:u24.04-container-latest` | essentials | `all-container` | ~1.25 GB / ~4 GB | Docker/containers tooling |
| **python** | `ghcr.io/jul-m/gha-runner-compose:u24.04-python-latest` | essentials | `all-python` | ~1.25 GB / ~4.75 GB | Python runtimes & tooling |
| **dotnet** | `ghcr.io/jul-m/gha-runner-compose:u24.04-dotnet-latest` | essentials | `all-dotnet` | ~2.25 GB / ~8 GB | .NET SDKs and tooling |
| **build** | `ghcr.io/jul-m/gha-runner-compose:u24.04-build-latest` | essentials | `all-build` (build tools, compilers) | ~2.25 GB / ~8.75 GB | For heavy build workloads |
| **medium** | `ghcr.io/jul-m/gha-runner-compose:u24.04-medium-latest` | build | Aggregated: cloud, nodejs, java, container, python, rust | ~5 GB / ~20 GB | Mid-size image for common stacks |
| **large** | `ghcr.io/jul-m/gha-runner-compose:u24.04-large-latest` | medium | medium + dotnet, php, ruby, R, Julia, web & DB tools | ~7.25 GB / ~29 GB | Large aggregate image |
| **xlarge** | `ghcr.io/jul-m/gha-runner-compose:u24.04-xlarge-latest` | large | large + swift, actions-cache, codeql, firefox, selenium | ~9.5 GB / ~35.5 GB | Very large; includes browsers & QA tools |
| **all** | `ghcr.io/jul-m/gha-runner-compose:u24.04-all-latest` | xlarge | everything not in xlarge (all components) | AMD64: ~15.5 GB / ~62 GB<br>ARM64: ~10.5 GB / ~44 GB | Full image; many AMD64-only components present on AMD64 |

For a full component breakdown per category see [docs/components.md](./components.md).


## Base Image

The `base` image serves as the foundation for all other runner images.

- **Source**: Built from the `base` stage in the Dockerfile, using `ubuntu:24.04` as its parent.
- **Contents**: Includes installation sources, prerequisite packages, the `runner` user setup, and the entrypoint script.
- **Usage**: It can be used as a standalone GitHub Actions runner, but it only contains the essential prerequisites, with no additional components.
- **Naming**: `ghcr.io/jul-m/gha-runner-compose-base:u24.04-<date>`, where:
  - `u24.04`: Indicates the base Ubuntu version.
  - `<date>` is the release date in `ddmmyy` format (e.g., `250919`). The `latest` tag always points to the most recent build.
- **Build Argument**: Use this as the `BASE_IMAGE` value when building a custom image from scratch.

**Key Information:**
- **Latest Image Tag**: `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`
- **Example `BASE_IMAGE`**: `BASE_IMAGE=ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`
- **Approximate Size** (compressed/uncompressed): ~300 MB / ~1.25 GB


## Runner Images

Runner images are built on top of the `base` image and include various sets of components.

The images follow this naming convention: `ghcr.io/jul-m/gha-runner-compose:u24.04-<type>-<date>`, where:
- `u24.04`: Indicates the base Ubuntu version.
- `<type>`: Defines the image content and size. It can be one of the following:
  - `essentials`: The base image plus components from the `essentials` category.
  - Thematic images (e.g., `nodejs`, `cloud`, `java`): Built on `essentials` and include all components of a specific category.
  - Sized images (`medium`, `large`, `xlarge`): Incrementally built images that aggregate multiple component categories.
  - `all`: An image containing all available components.
- `<date>`: The build date in `ddmmyy` format (e.g., `250923`), matching with the base image. The `latest` tag always points to the most recent build.

### Layered Build Strategy

Our images are built incrementally, with each layer adding new components on top of the previous one. This approach provides several benefits:
- **Faster Builds**: Avoids rebuilding same components multiple times.
- **Reduced Storage**: Common layers are shared across images, optimizing disk and registry space.
- **Reduced Bandwidth Usage**: When several images are pulled, shared layers are downloaded only once.
- **Flexible Customization**: You can extend the most suitable pre-built image to create your own custom runner with minimal effort.

**Best Practice**: When building a custom runner, select the pre-built image that already contains most of your required tools. For instance, if you need Java, Python, and various cloud CLIs, start from the `medium` image instead of building from the `base`.


### Available Runner Images

#### Essentials Image
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest`
- **Based on**: `base`
- **Contents**: `all-essentials` category (`apt-common`, `git`, `git-lfs`, `github-cli`, `nodejs-lite`, `runner-package`, `yq`, `zstd`).
- **Approximate Size** (compressed/uncompressed): ~800 MB / ~2.75 GB

#### Thematic Images (Based on `essentials`)
- **NodesJS**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-nodejs-latest`
  - **Content**: `all-nodejs`
  - **Approximate Size** (compressed/uncompressed): ~1GB / ~4 GB
- **Cloud**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-cloud-latest`
  - **Content**: `all-cloud`
  - **Approximate Size** (compressed/uncompressed): ~1.5GB / ~6.5 GB
- **Java**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-java-latest`
  - **Content**: `all-java`
  - **Approximate Size** (compressed/uncompressed): ~2GB / ~6 GB
- **Container**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-container-latest`
  - **Content**: `all-container`
  - **Approximate Size** (compressed/uncompressed): ~1.25 GB / ~4 GB
- **Python**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-python-latest`
  - **Content**: `all-python`
  - **Approximate Size** (compressed/uncompressed): ~1.25 GB / ~4.75 GB
- **DotNet**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-dotnet-latest`
  - **Content**: `all-dotnet`
  - **Approximate Size** (compressed/uncompressed): ~2.25 GB / ~8 GB
- **Build Tools**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-build-latest`
  - **Content**: `all-build` (plus `nodejs` as a dependency).
  - **Approximate Size** (compressed/uncompressed): ~2.25 GB / ~8.75 GB

#### Larger Aggregate Images
- **Medium**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-medium-latest`
  - **Based on**: `build`
  - **Additional Components**: `all-cloud`, `all-nodejs`, `all-java`, `all-container`, `all-python`, `all-rust`.
  - **Approximate Size** (compressed/uncompressed): ~5 GB / ~20 GB

- **Large**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-large-latest`
  - **Based on**: `medium`
  - **Additional Components**: `all-dotnet`, `all-php`, `all-ruby`, `all-r`, `all-julia`, `pipx-packages`, `all-web`, `all-databases`.
  - **Approximate Size** (compressed/uncompressed): ~7.25 GB / ~29 GB

- **X-Large**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-xlarge-latest`
  - **Based on**: `large`
  - **Additional Components**: `all-swift`, `actions-cache`, `codeql-bundle`, `firefox`, `selenium`.
  - **Approximate Size** (compressed/uncompressed): ~9.5 GB / ~35.5 GB

- **ALL**:
  - **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-all-latest`
  - **Based on**: `xlarge`
  - **Additional Components**: All remaining components not included in `xlarge`.
  - Most components compatible only with AMD64 are present in the AMD64 version of this image.
  - **Approximate Size for AMD64 version** (compressed/uncompressed): ~15.5 GB / ~62 GB
  - **Approximate Size for ARM64 version** (compressed/uncompressed): ~10.5 GB / ~44 GB


## Notes

- **Components List:** For a detailed list of all available components and their status, see [docs/components.md](./components.md).
- **`all-<category>` Notation:** A tag like `all-nodejs` or `all-cloud` installs all components belonging to that category. Categories are defined in [docker-build/local-install/components.csv](../docker-build/local-install/components.csv) and documented in [docs/components.md](./components.md).
- The Approximate Sizes are provided for informational purposes only and may vary due to several factors (especially between AMD64 and ARM64 versions). The size indicated includes all layers of the image for a single architecture. If you have already pulled other images from this repository with shared layers, the additional space used will be lower. If you pull both the AMD64 and ARM64 versions of the images, the size will be twice as large (no shared layers between the two architectures).