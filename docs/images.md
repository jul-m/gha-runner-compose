# Pre-Built Images

This document outlines the pre-built Docker images available for this project, their contents, and the strategy behind them.

## Base Image

The `base` image serves as the foundation for all other runner images.

- **Source**: Built from the `base` stage in the Dockerfile, using `ubuntu:24.04` as its parent.
- **Contents**: Includes installation sources, prerequisite packages, the `runner` user setup, and the entrypoint script.
- **Usage**: It can be used as a standalone GitHub Actions runner, but it only contains the essential prerequisites, with no additional components.
- **Naming**: `ghcr.io/jul-m/gha-runner-compose-base:u24.04-<date>`, where `<date>` is the release date (e.g., `240919`). The `latest` tag always points to the most recent build.
- **Build Argument**: Use this as the `BASE_IMAGE` value when building a custom image from scratch.

**Key Information:**
- **Latest Image Tag**: `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`
- **Example `BASE_IMAGE`**: `BASE_IMAGE=ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`
- **Approximate Size**: ~1.3 GB

## Runner Images

Runner images are built on top of the `base` image and include various sets of components.

The images follow this naming convention: `ghcr.io/jul-m/gha-runner-compose:u24.04-<type>-latest`, where:
- `u24.04`: Indicates the base Ubuntu version.
- `<type>`: Defines the image content and size. It can be one of the following:
  - `essentials`: The base image plus components from the `essentials` category.
  - Thematic images (e.g., `nodejs`, `cloud`, `java`): Built on `essentials` and include all components of a specific category.
  - Sized images (`medium`, `large`, `xlarge`): Incrementally built images that aggregate multiple component categories.
  - `all`: An image containing all available components.

### Layered Build Strategy

Our images are built incrementally, with each layer adding new components on top of the previous one. This approach provides several benefits:
- **Faster Builds**: Avoids rebuilding common components from scratch.
- **Reduced Storage**: Common layers are shared across images, optimizing disk and registry space.
- **Flexible Customization**: You can extend the most suitable pre-built image to create your own custom runner with minimal effort.

**Best Practice**: When building a custom runner, select the pre-built image that already contains most of your required tools. For instance, if you need Java, Python, and various cloud CLIs, start from the `medium` image instead of building from the `base`.

### Available Runner Images

#### Essentials Image
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest`
- **Based on**: `base`
- **Contents**: `all-essentials` category (`apt-common`, `git`, `git-lfs`, `github-cli`, `nodejs-lite`, `runner-package`, `yq`, `zstd`).
- **Size**: ~2.6 GB

#### Thematic Images (Based on `essentials`)
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-nodejs-latest`
  - **Contents**: `all-nodejs`
  - **Size**: (Size TBD)
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-cloud-latest`
  - **Contents**: `all-cloud`
  - **Size**: (Size TBD)
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-java-latest`
  - **Contents**: `all-java`
  - **Size**: ~5.3 GB
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-container-latest`
  - **Contents**: `all-container`
  - **Size**: (Size TBD)
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-python-latest`
  - **Contents**: `all-python`
  - **Size**: (Size TBD)
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-dotnet-latest`
  - **Contents**: `all-dotnet`
  - **Size**: (Size TBD)
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-build-latest`
  - **Contents**: `all-build` (plus `nodejs` as a dependency).
  - **Size**: ~8.5 GB

#### Larger Aggregate Images
- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-medium-latest`
  - **Based on**: `build`
  - **Additional Components**: `all-cloud`, `all-nodejs`, `all-java`, `all-container`, `all-python`, `all-rust`.
  - **Size**: ~18.1 GB

- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-large-latest`
  - **Based on**: `medium`
  - **Additional Components**: `all-dotnet`, `all-php`, `all-ruby`, `all-r`, `all-julia`, `pipx-packages`, `all-web`, `all-databases`.
  - **Size**: ~27.4 GB

- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-xlarge-latest`
  - **Based on**: `large`
  - **Additional Components**: `all-swift`, `actions-cache`, `codeql-bundle`, `firefox`, `selenium`.
  - **Size**: ~35.3 GB

- **Image**: `ghcr.io/jul-m/gha-runner-compose:u24.04-all-latest`
  - **Based on**: `xlarge`
  - **Additional Components**: All remaining components not included in `xlarge`.
  - **Size**: ~43.3 GB

---

**Notes:**

- **Components List:** For a detailed list of all available components and their status, see [docs/components.md](./components.md).
- **`all-<category>` Notation:** A tag like `all-nodejs` or `all-cloud` installs all components belonging to that category. Categories are defined in `docker-build/local-install/components.csv` and documented in `docs/components.md`.
