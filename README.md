
# gha-runner-compose

> Run your GitHub Actions workflows in containers that faithfully replicate GitHub-hosted runners.

> [Version Française - French Version](./README.FR.md)

This project provides Docker images and the necessary tools to build and launch self-hosted GitHub Actions runners in an environment equivalent to the Ubuntu runners provided by GitHub. Using Docker offers a fast and flexible solution for hosting your runners, whether to benefit from more powerful resources, bypass certain limitations of standard runners, or run ARM64 workflows on private repositories. This project is also designed to serve as a basis for local testing of GitHub Actions workflows with tools like [act](https://github.com/nektos/act), ensuring a test environment as close as possible to that of the official runners.

Under the hood, this project relies on the same scripts used by `actions/runner-images` to install software components. You can either use a pre-built image or generate your own images by precisely selecting the components to include to optimize the final size.

> [!WARNING]
> This project is under active development. Some features may be unstable, and major changes are expected. The generated images are currently intended for testing and development purposes.

---

## Table of Contents
- [gha-runner-compose](#gha-runner-compose)
  - [Table of Contents](#table-of-contents)
  - [Quick Start](#quick-start)
    - [Choose or Build an Image](#choose-or-build-an-image)
    - [Deploy a Self-Hosted GitHub Runner](#deploy-a-self-hosted-github-runner)
    - [Test Your Workflows Locally](#test-your-workflows-locally)
  - [Generate Custom Images (without Docker Compose)](#generate-custom-images-without-docker-compose)
    - [General Case](#general-case)
    - [Base Image](#base-image)
    - [Advanced Build](#advanced-build)
  - [How the Build Works](#how-the-build-works)
  - [Entrypoint](#entrypoint)
  - [Repository Structure](#repository-structure)
  - [License](#license)
  - [Disclaimer — No Warranty and Limitation of Liability](#disclaimer--no-warranty-and-limitation-of-liability)

---

## Quick Start
### Choose or Build an Image

The official GitHub runner images are built from a set of scripts, each installing a specific component. This project offers an image containing all components (`<image-tag>`), but it is large. The Docker build system implemented here allows you to create custom images containing only the necessary components to optimize their size. The list of available components is provided in [docs/components.md](./docs/components.md). Pre-built images grouping sets of components are also available (see [docs/images.md](./docs/images.md)).

Three scenarios are possible:

1.  **Use a pre-built image as is:**
    -   No build is necessary; startup is immediate.
    -   *Example:* In `compose.yml`, update the line `image: ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest` with the desired image.
2.  **Extend a pre-built image:**
    -   Ideal if an existing image almost suits you, but a few tools are missing. You can add only the missing components instead of rebuilding everything.
    -   *Example:* In `compose.build.yml`, update the build arguments:
        -   `BASE_IMAGE`: The base image to extend (e.g., `ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest`).
        -   `RUNNER_COMPONENTS`: A list of components to add. Components already present in the base image will be ignored.
3.  **Build an image from scratch:**
    -   Recommended if no pre-built image meets your needs or if you want to optimize the image size as much as possible.
    -   You can:
        -   Start from the `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest` image, which contains only the prerequisites (`BASE_IMAGE=ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`).
        -   Build from an official Ubuntu 24.04 image by removing the `BASE_IMAGE` argument (or setting it to `base`).
    -   Then, list all the desired components in `RUNNER_COMPONENTS` (e.g., `RUNNER_COMPONENTS=yq,docker,java-tools`).

To build a custom image, you can use:
-   **Docker Compose** with the [compose.build.yml](./compose.build.yml) file (see the next section).
-   The **`docker buildx build`** command (see the [Generate Custom Images](#generate-custom-images-without-docker-compose) section).

The complete list of components and categories is available in [docs/components.md](./docs/components.md). It is possible to install an entire category by specifying `all-<category>`. Note that some components are not available on the ARM64 architecture.

### Deploy a Self-Hosted GitHub Runner

If you have never used self-hosted GitHub runners, consult the [official GitHub documentation](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners) before you begin.

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/jul-m/gha-runner-compose.git
    cd gha-runner-compose
    ```
2.  **Generate a registration token:**
    -   Go to the settings of the target repository or organization: `Settings` > `Actions` > `Runners` > `New self-hosted runner`.
    -   Copy the value of the `--token` argument displayed in the configuration command.
    -   **Note:** This token has a limited lifetime (about one hour).

3.  **Configure your environment:**
    -   Copy the [.env.example](./.env.example) template to a `.env` file.
    -   Edit the necessary values:
        -   `RUNNER_REPO_URL`: URL of the target — repository (`https://github.com/<owner>/<repo>`) or organization (`https://github.com/<org>`).
        -   `RUNNER_TOKEN`: Registration token generated in the previous step.
        -   `RUNNER_LABELS` (optional): Custom labels, separated by commas.

4.  **Prepare your Docker Compose file:**
    -   Choose between `compose.yml` (pre-built image) and `compose.build.yml` (custom build).
    -   **If you use `compose.yml` (existing image):**
        -   Modify the `image` directive to specify the desired image.
    -   **If you use `compose.build.yml` (custom build):**
        -   To extend an image:
            -   `build.args.BASE_IMAGE`: Base image to extend.
            -   `build.args.RUNNER_COMPONENTS`: List of components to add.
        -   To build from scratch:
            -   Remove or comment out the `BASE_IMAGE` line.
            -   `build.args.RUNNER_COMPONENTS`: Complete list of components to include.
    -   **In all cases:**
        -   `env_file`: Ensure it references your `.env` file.
        -   `environment.RUNNER_NAME`: A unique name for your runner.
        -   `privileged: true`: **Only enable this if your workflows require Docker (Docker-in-Docker)**. The `docker` component must be included in the image.
          > [!WARNING]
          > Enabling this mode has significant security implications. Only use it if you understand the risks.
        -   **Volume `/opt/actions-runner`:**
            -   This volume ensures the persistence of the runner's configuration. The registration token is only used on the first start.
            -   If you destroy the volume, you will need to generate a new token to re-register the runner.
            -   **Use a separate volume for each runner instance.**

5.  **Launch the container(s):**
    ```bash
    # For a custom build
    docker compose -f compose.build.yml up -d --build

    # For a pre-built image
    docker compose -f compose.yml up -d
    ```
    The build time depends on the number of components to install and your connection speed.

6.  **Check the runner's status:**
    -   **Container logs:**
      ```shell
      # Authentication
      √ Connected to GitHub
      # Runner Registration
      √ Runner successfully added
      √ Runner connection is good
      # Runner settings
      √ Settings Saved.
      [entrypoint.sh] Starting runner...
      [entrypoint.sh] Runner started - PID: 65 PGID: 1
      √ Connected to GitHub
      Current runner version: '2.328.0'
      2025-XX-XX XX:XX:XXZ: Listening for Jobs
      ```
    -   **GitHub interface:** The runner should appear as "Idle" in `Settings` > `Actions` > `Runners`.
    -   The container logs also display the list of installed components. You can also check the `/imagegeneration/installed/components.txt` file in the container.

**Common errors:**
-   **Registration failure:**
  ```
  Http response code: NotFound from 'POST https://api.github.com/actions/runner-registration'
  Response status code does not indicate success: 404 (Not Found).
  [entrypoint.sh][ERROR] Failed to configure runner
  ```
  This error is usually due to an expired token or an incorrect repository/organization URL. Check the `RUNNER_REPO_URL` and `RUNNER_TOKEN` variables in your `.env` file.

---

### Test Your Workflows Locally

It is possible to test your GitHub Actions workflows locally to facilitate development and debugging. Tools like [act](https://github.com/nektos/act) simulate the action execution environment. The images from this project provide a faithful test environment with an optimized image size.

> [!IMPORTANT]
> To work with `act`, the `nodejs` component must be included in the image, in addition to the components required by your workflows. All pre-built `ghcr.io/jul-m/gha-runner-compose:u24.04-*` images include `nodejs-lite`, which is sufficient. The base image `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest` does not contain it.

To use `act` with `gha-runner-compose`:
-   If you are building a custom image, follow the instructions in the [Generate Custom Images](#generate-custom-images-without-docker-compose) section.
-   Use the `-P` option to map runner labels to Docker images. For example, to use the `ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest` image for `ubuntu-latest` jobs:
  ```bash
  act -P ubuntu-latest=ghcr.io/jul-m/gha-runner-compose:u24.04-essentials-latest
  ```
-   If you are using a locally built image, add the `--pull=false` option to prevent `act` from trying to download it from a public registry:
  ```bash
  act -P ubuntu-latest=<your-image-name> --pull=false
  ```
-   If you get a `node: command not found` error, check that the `nodejs` or `nodejs-lite` component is included in your image.
-   If your workflows use Docker (Docker-in-Docker), enable privileged mode with `--privileged` and ensure the `docker` component is present in the image. **Be aware of the security implications; only enable it if you are fully aware of the risks and trust the code you are running!**
-   For more details, consult the [official `act` documentation](https://nektosact.com/).

---

## Generate Custom Images (without Docker Compose)
### General Case
You can build custom images using `docker buildx build`. To speed up the process, it is recommended to start from an image that already contains some of the desired components. For full control, start from the base image `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`.

**Base command:**
```bash
docker buildx build \
    --build-arg BASE_IMAGE=ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest \
    --build-arg RUNNER_COMPONENTS=java-tools,yq \
    --target runner-build \
    -t my-gha-runner:java-latest .
```

**Build arguments:**
-   `--build-arg <arg>=<value>`:
    -   `BASE_IMAGE`: The base image to use. To build from a clean Ubuntu 24.04 image, do not specify this argument or set it to `base`.
    -   `RUNNER_COMPONENTS`: A comma-separated list of components and categories (`all-<category>`) to include. Components already present in the base image will be ignored. The full list is available in [docs/components.md](./docs/components.md).
    -   `APT_PACKAGES` (optional): A comma-separated list of additional APT packages to install.
    -   `PWSH_MODULES` (optional): A comma-separated list of additional PowerShell modules to install (e.g., `Microsoft.Graph,Az`).
-   `--target <stage>`: Must be `runner-build` for a functional image. The `base` stage only generates the prerequisite layer.
-   `-t <image-name>`: Name of the resulting image.
-   `--platform <platform>` (optional): Target platform (e.g., `linux/amd64`, `linux/arm64`). Requires a `buildx` builder configured for multi-architecture.
-   `--progress=plain` (optional): Displays the full build logs in the terminal.
-   `.`: Build context (the root directory of this repository).

### Base Image

To build the base image containing only the prerequisites (equivalent to `ghcr.io/jul-m/gha-runner-compose-base:u24.04-latest`), use the `base` stage:

```bash
docker buildx build \
    --target base \
    -t my-gha-runner-base:latest .
```

### Advanced Build

To optimize multiple builds, you can use a dedicated BuildKit builder that leverages the download cache.

1.  **Create the dedicated builder:**
    ```bash
    docker buildx create --driver docker-container \
        --name gha-runner-compose-builder --config ./buildkitd.toml
    ```

2.  **Launch the build with this builder:**
    ```bash
    docker build --build-arg RUNNER_COMPONENTS=all \
        --target runner-build --progress=plain \
        -t my-gha-runner:all-latest \
        --builder gha-runner-compose-builder --load .
    ```
    The `--load` option is necessary to load the image into the local Docker engine.

#### Optional: Increase GitHub API Rate Limits During Build

Some upstream scripts download assets from GitHub (releases, raw files, API metadata). Anonymous requests are heavily rate‑limited. You can optionally provide a GitHub token (classic PAT or a fine‑grained token with public repo scope) **without baking it into the image layers** by using a BuildKit secret. The custom curl/wget wrappers automatically add an `Authorization: Bearer` header for GitHub domains when `GITHUB_TOKEN` is available.

1. Provide the token to BuildKit. You can export it as an environment variable **or** reference a file directly:
```bash
# Option A: environment variable (used by --secret env=...)
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxx

# Option B: store it in a file and reference it later
echo "ghp_xxxxxxxxxxxxxxxxxxxxx" > ~/.config/github-token
```
2. Pass it as a secret when building:
```bash
docker buildx build \
    --secret id=GITHUB_TOKEN,env=GITHUB_TOKEN \  # with Option A
    --build-arg RUNNER_COMPONENTS=yq,docker,java-tools \
    --target runner-build -t my-runner:latest .

# or, using Option B
docker buildx build \
    --secret id=GITHUB_TOKEN,src=$HOME/.config/github-token \
    --build-arg RUNNER_COMPONENTS=yq,docker,java-tools \
    --target runner-build -t my-runner:latest .
```
3. Or with docker compose (example snippet inside your service):
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

## How the Build Works

The build pipeline relies on a multi-stage `Dockerfile` and reuses the official scripts from `actions/runner-images` (for Ubuntu) with local scripts to orchestrate component installation.

-   **Source of upstream scripts:** The scripts come from the `runner-images-src/` Git submodule. To ensure stability and security, a frozen version of these scripts is copied to `docker-assets/from-upstream/` and used during the build.

-   **Main `Dockerfile` stages:**
    1.  **`base`:**
        -   Copies the frozen upstream scripts and assets from `docker-assets/from-upstream/` to `/imagegeneration/`, and local build logic from `docker-build/` to `/imagegeneration/docker-build/`.
        -   Enables APT caching during build (temporarily disables `docker-clean` and symlinks `zz-disable-apt-clean.conf`), installs base packages, creates the `runner` user and directories, then runs `local-install/install-prereqs.sh` (installs the GitHub Actions runner, PowerShell, repositories). Finally restores APT settings via `local-install/clean-restore.sh`.
        -   Sets the container startup: copies `entrypoint.sh`, sets `ENTRYPOINT ["/entrypoint.sh"]`, `USER runner`, and `WORKDIR` to `${RUNNER_WORKDIR}`.
    2.  **`runner-build`:**
        -   Inherits from `${BASE_IMAGE}` (defaults to the `base` stage). It does not re-copy sources; it expects `/imagegeneration/` from the base image.
        -   Re-enables the APT cache optimization during component installation, runs `local-install/install-components.sh` driven by `RUNNER_COMPONENTS` and optional `APT_PACKAGES` and `PWSH_MODULES`, then restores APT settings.
        -   Resolves dependencies and categories (`all`, `all-<category>`) defined in `local-install/components.csv`, and records installed components in `/imagegeneration/installed/components.txt` to avoid reinstallation.
    3.  **Resulting image:**
        -   The `runner-build` stage is the one you should tag/use as the final image.

-   **Component override logic:**
    -   For each component `<comp>`, the orchestrator first looks for a local script `docker-build/components/<comp>.sh`.
    -   **If it exists:** this script is executed. It has the ability to modify the corresponding upstream script (for example, to adapt it for ARM64 or a container context) before calling it.
    -   **Otherwise:** the upstream script `/imagegeneration/build/install-<comp>.sh` is executed directly.

-   **Utility wrappers (`./docker-build/bin/`):**
    -   `systemctl`: A fake `systemd` that redirects calls to `service` or `init.d` scripts, allowing upstream scripts to work in a container.
    -   `curl` and `wget`: Wrappers that cache downloaded artifacts in `/var/cache/gha-download-cache` (cached by BuildKit), reducing build times. APT metadata and packages are also cached via BuildKit cache mounts.

---

## Entrypoint

The `/entrypoint.sh` script manages the runner's lifecycle in the container:
-   **Initial checks:** Requires `RUNNER_TOKEN` on the first start.
-   **Label configuration:** Applies default labels (`docker-runner`, `docker-runner-<arch>`) if `RUNNER_LABELS` is not defined.
-   **Runner management:** Ensures the runner binary is present and displays the list of installed components.
-   **Conditional registration:** Executes `config.sh` only if the runner is not already configured (i.e., if the `.runner` file does not exist).
-   **Execution and clean shutdown:** Launches `run.sh` in the background and traps signals (`SIGINT`, `SIGTERM`) to ensure a graceful shutdown of the runner.

---

## Repository Structure

-   `Dockerfile`: Multi-stage build file.
-   `compose.*.yml`: Docker Compose files for different use cases.
-   `buildkitd.toml`: BuildKit configuration for build caching.
-   `docker-assets/`: Files copied into the Docker image.
    -   `entrypoint.sh`: Container startup script.
    -   `from-upstream/`: Frozen copy of scripts and `toolset.json` from `actions/runner-images`.
-   `docker-build/`: Custom build logic.
    -   `local-install/`: Orchestration scripts (`install-prereqs.sh`, `install-components.sh`), `helpers.sh`, and `components.csv` (component definitions).
    -   `components/`: Override scripts to adapt specific component installations.
    -   `bin/`: Wrappers for `systemctl`, `curl`, and `wget`.
-   `docs/`: Additional documentation (components, images).
-   `runner-images-src/` (Git submodule): Mirror of the `actions/runner-images` repository, used as a source for upstream scripts.

---

## License
-   **Upstream sources (`runner-images-src/`, `docker-assets/from-upstream/`):** This content comes from `actions/runner-images` and is distributed under the original MIT License. Copyright belongs to "Microsoft Corporation and contributors".
-   **This repository (original code):** Unless otherwise stated, the code is governed by the license specified in the [LICENSE](LICENSE) file at the root of the repository. This project is independent and is not affiliated with, sponsored by, or endorsed by GitHub, Inc. or Microsoft Corporation.

---

## Disclaimer — No Warranty and Limitation of Liability
This project is provided "AS IS", without any express or implied warranty, including, but not limited to, the warranties of merchantability, fitness for a particular purpose, and non-infringement.
In no event shall the author or contributors be liable for any direct, indirect, incidental, special, exemplary, or consequential damages resulting from the use or inability to use this project.
You use this project at your own risk and are solely responsible for complying with applicable laws, security policies, and contractual obligations.
