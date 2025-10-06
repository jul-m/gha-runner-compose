# Available Components
## Components List

This document lists the components that can be enabled in the Docker image via the `RUNNER_COMPONENTS` build argument, along with their compatibility and integration status.

| <ins>Component Name</ins> | <ins>Override</ins> | <ins>Categories</ins> | <ins>Content</ins> | <ins>Prebuilt Image</ins> | <ins>x86_64</ins> | <ins>ARM64</ins> | <ins>Notes</ins> |
| --- | --- | --- | --- | --- | :---: | :---: | --- |
| `actions-cache` | No | `other` | [actions/action-versions](https://github.com/actions/action-versions) | `xlarge+` |  |  |  |
| `android-sdk` | No | `other` | Android SDK + NDK | `all` |  | ❌ | Not available on Linux ARM64 |
| `apache` | No | `web` | Apache HTTP Server ([httpd.apache.org](https://httpd.apache.org/)) | `large+` | ✅ | ✅ |  |
| `apt-common` | Pkg ambiguity | `essentials,system` | Common apt packages (list in [toolset.json](../docker-assets/from-upstream/toolset.json)) | `essentials+` | ✅ | ✅ |  |
| `apt-vital` | *Skip install* | `prerequs` | Vital apt packages (list in [toolset.json](../docker-assets/from-upstream/toolset.json)) | `base+` | ✅ | ✅ | Already installed in prereqs phase |
| `aws-tools` | ARM64 | `cloud` | [aws/aws-cli](https://github.com/aws/aws-cli), [aws/session-manager-plugin](https://github.com/aws/session-manager-plugin), [aws/aws-sam-cli](https://github.com/aws/aws-sam-cli) | `medium+`, `cloud` |  |  |  |
| `azcopy` | ARM64 | `cloud` | [Azure/azure-storage-azcopy](https://github.com/Azure/azure-storage-azcopy) | `medium+`, `cloud` |  |  |  |
| `azure-cli` | No | `cloud` | [Azure/azure-cli](https://github.com/Azure/azure-cli) | `medium+`, `cloud` |  |  |  |
| `azure-devops-cli` | No | `cloud` | [Azure/azure-devops-cli-extension](https://github.com/Azure/azure-devops-cli-extension) | `medium+`, `cloud` |  |  | Requires `azure-cli` |
| `bazel` | No | `build` | [bazelbuild/bazelisk](https://github.com/bazelbuild/bazelisk) | `medium+`, `build` |  |  | Requires `nodejs` |
| `bicep` | ARM64 | `cloud` | [Azure/bicep](https://github.com/Azure/bicep) | `medium+`, `cloud` |  |  |  |
| `clang` | No | `build` | Clang/LLDB + format/tidy (versions in [toolset.json](../docker-assets/from-upstream/toolset.json)) | `medium+`, `build` |  |  |  |
| `cmake` | ARM64 | `build` | [Kitware/CMake](https://github.com/Kitware/CMake) | `medium+`, `build` |  |  |  |
| `codeql-bundle` | No | `other` | [github/codeql-action](https://github.com/github/codeql-action) | `xlarge+` |  | ⚠️ | Build ARM64 OK but packages appears targeted at AMD64, no post-install tests → needs tests on ARM64 |
| `container-tools` | Docker | `container` | [containers/podman](https://github.com/containers/podman), [containers/buildah](https://github.com/containers/buildah), [containers/skopeo](https://github.com/containers/skopeo) | `medium+`, `container` |  | ❌ | Enabled only for x64, can maybe adapted for ARM64 later. Override script disable tests, Docker not available on image build. |
| <ins>**Component Name**</ins> | <ins>**Override**</ins> | <ins>**Categories**</ins> | <ins>**Content**</ins> | <ins>**Prebuilt Image**</ins> | <ins>**x86_64**</ins> | <ins>**ARM64**</ins> | <ins>**Notes**</ins> |
| `docker` | Docker, ARM64 | `container` | [docker/cli](https://github.com/docker/cli), [docker/buildx](https://github.com/docker/buildx), [docker/compose](https://github.com/docker/compose) | `medium+`, `container` | ✅ |  |  |
| `dotnetcore-sdk` | No | `dotnet` | .NET SDKs (versions in [toolset.json](../docker-assets/from-upstream/toolset.json)) | `large+`, `dotnet` |  |  |  |
| `firefox` | ARM64 | `browser` | [mozilla/geckodriver](https://github.com/mozilla/geckodriver), [ppa:mozillateam/ppa](https://launchpad.net/~mozillateam/+archive/ubuntu/ppa) | `xlarge+` |  |  |  |
| `gcc-compilers` | No | `build` | GCC/G++ toolchains | `medium+`, `build` |  |  |  |
| `gfortran` | No | `build` | GFortran toolchains | `medium+`, `build` |  |  |  |
| `git-lfs` | No | `essentials,system` | [git-lfs/git-lfs](https://github.com/git-lfs/git-lfs) | `essentials+` |  |  |  |
| `git` | No | `essentials,system` | Git + git-ftp ([ppa:git-core/ppa](https://launchpad.net/~git-core/+archive/ubuntu/ppa)) | `essentials+` | ✅ | ✅ |  |
| `github-cli` | ARM64 | `essentials,system` | GitHub CLI ([cli/cli](https://github.com/cli/cli)) | `essentials+` | ✅ | ✅ |  |
| `google-chrome` | No | `browser` | Chrome + chromedriver | `all` |  | ❌ | Chrome not available on Linux ARM64 (override for install Chromium on ARM64 can maybe be added) |
| `google-cloud-cli` | No | `cloud` | Google Cloud SDK (gcloud) | `medium+`, `cloud` |  |  |  |
| `haskell` | No | `haskell` | [haskell/ghcup-hs](https://github.com/haskell/ghcup-hs) | `all` |  |  |  |
| `heroku` | No | `cloud` | [heroku/cli](https://github.com/heroku/cli) | `medium+`, `cloud` |  |  |  |
| `homebrew` | Install as non-root | `system` | [Homebrew/brew](https://github.com/Homebrew/brew) | `all` |  |  |  |
| `java-tools` | ARM64 | `java` | Temurin JDKs 8/11/17/21 ([Adoptium](https://adoptium.net/)) + [Maven](https://maven.apache.org/) + [Gradle](https://gradle.org/) + [Ant](https://ant.apache.org/) | `medium+`, `java` | ✅ | ✅ |  |
| `julia` | ARM64 | `julia` | [JuliaLang/julia](https://github.com/JuliaLang/julia) | `large+` |  |  |  |
| <ins>**Component Name**</ins> | <ins>**Override**</ins> | <ins>**Categories**</ins> | <ins>**Content**</ins> | <ins>**Prebuilt Image**</ins> | <ins>**x86_64**</ins> | <ins>**ARM64**</ins> | <ins>**Notes**</ins> |
| `kotlin` | No | `java` | [JetBrains/kotlin](https://github.com/JetBrains/kotlin) | `medium+`, `java` |  |  | Requires `java-tools` |
| `kubernetes-tools` | ARM64 | `container` | [kubernetes/kubectl](https://github.com/kubernetes/kubectl), [helm/helm](https://github.com/helm/helm), [kubernetes/minikube](https://github.com/kubernetes/minikube), [kubernetes-sigs/kind](https://github.com/kubernetes-sigs/kind), [kubernetes-sigs/kustomize](https://github.com/kubernetes-sigs/kustomize) | `medium+`, `container` |  |  |  |
| `leiningen` | No | `java` | [technomancy/leiningen](https://github.com/technomancy/leiningen) | `medium+`, `java` |  |  | Requires `java-tools` |
| `microsoft-edge` | No | `browser` | Edge browser + driver | `all` |  | ❌ | MS Edge not available on Linux ARM64 |
| `miniconda` | ARM64 | `python` | [conda/miniconda](https://github.com/conda/miniconda) | `medium+`, `python` |  |  |  |
| `ms-repos` | *Skip install* | `prerequs` | Microsoft apt repo | `base+` | ✅ | ✅ | Already installed in prereqs phase |
| `mysql` | No | `databases` | MySQL server + client ([mysql/mysql-server](https://github.com/mysql/mysql-server)) | `large+` |  |  |  |
| `nginx` | No | `web` | Nginx web server ([nginx/nginx](https://github.com/nginx/nginx)) | `large+` |  |  |  |
| `ninja` | ARM64 | `build` | [ninja-build/ninja](https://github.com/ninja-build/ninja) | `medium+`, `build` |  |  | Requires `cmake` |
| `nodejs` | No | `nodejs` | Node.js LTS + npm tools (list in [toolset.json](../docker-assets/from-upstream/toolset.json)) | `medium+`, `nodejs`, `build` | ✅ | ✅ |  |
| `nodejs-lite` | *Lite Version* | `lite,essentials` | Lite version of `nodejs` (Install node without modules) | `essentials+` | ✅ | ✅ | Ignored if `nodejs` installed |
| `nvm` | No | `nodejs` | Node Version Manager [nvm-sh/nvm](https://github.com/nvm-sh/nvm) | `medium+`, `nodejs` |  |  |  |
| `oc-cli` | No | `cloud` | OpenShift Command Line [openshift/oc](https://github.com/openshift/oc) | `medium+`, `cloud` |  |  |  |
| `oras-cli` | ARM64 | `cloud` | OCI registry client [oras-project/oras](https://github.com/oras-project/oras) | `medium+`, `cloud` |  |  |  |
| `packer` | ARM64 | `build` | [hashicorp/packer](https://github.com/hashicorp/packer) image builder | `medium+`, `build` |  |  |  |
| <ins>**Component Name**</ins> | <ins>**Override**</ins> | <ins>**Categories**</ins> | <ins>**Content**</ins> | <ins>**Prebuilt Image**</ins> | <ins>**x86_64**</ins> | <ins>**ARM64**</ins> | <ins>**Notes**</ins> |
| `php` | No | `php` | PHP + [Composer](https://getcomposer.org/) + [PHPUnit](https://phpunit.de/) | `large+` |  |  |  |
| `pipx-packages` | No | `other` | Python tools installed by pipx (list in [toolset.json](../docker-assets/from-upstream/toolset.json)) | `large+` |  |  | Requires `python` |
| `postgresql` | No | `databases` | PostgreSQL server + libpq-dev | `large+` |  |  |  |
| `powershell` | *Skip install* | `prerequs` | PowerShell 7 (pwsh) | `base+` | ✅ | ✅ | Already installed in prereqs phase |
| `pulumi` | ARM64 | `cloud` | [pulumi/pulumi](https://github.com/pulumi/pulumi)  IaC | `medium+`, `cloud` | ✅ | ✅ |  |
| `pypy` | ARM64 | `python` | PyPy runtimes (versions in [toolset.json](../docker-assets/from-upstream/toolset.json)) | `medium+`, `python` |  |  |  |
| `python` | No | `python` | Python3 + pip + pipx | `medium+`, `python` | ✅ | ✅ |  |
| `rlang` | No | `r` | R Statistical Computing Language [r-project.org](https://r-project.org/) | `large+` |  |  |  |
| `ruby` | No | `ruby` | [ruby/ruby-builder](https://github.com/ruby/ruby-builder) | `large+` |  |  |  |
| `runner-package` | ARM64 | `essentials,system` | Caching [actions/runner](https://github.com/actions/runner) archive | `essentials+` | ✅ | ✅ | Package extracted by `entrypoint.sh` to `$RUNNER_INSTALL_DIR` if executed in self-hosted runner context |
| `rust` | No | `rust` | [rust-lang/rustup](https://github.com/rust-lang/rustup) + cargo | `medium+` |  |  |  |
| `sbt` | No | `java` | [sbt/sbt](https://github.com/sbt/sbt) build tool for Scala & Java | `medium+`, `java` |  |  |  |
| `selenium` | No | `browser` | [SeleniumHQ/selenium](https://github.com/SeleniumHQ/selenium) browser automation framework | `xlarge+` |  |  | Requires `java-tools` |
| `swift` | ARM64 | `swift` | [apple/swift](https://github.com/apple/swift) Programming Language | `xlarge+` |  |  |  |
| `vcpkg` | No | `build` | [microsoft/vcpkg](https://github.com/microsoft/vcpkg) C++ Library Manager | `medium+`, `build` |  |  |  |
| `yq` | ARM64 | `essentials` | [mikefarah/yq](https://github.com/mikefarah/yq) YAML, JSON and + processor | `essentials+` | ✅ | ✅ |  |
| `zstd` | No | `essentials` | [facebook/zstd](https://github.com/facebook/zstd) Fast real-time compression algorithm | `essentials+` |  |  |  |
| <ins>**Component Name**</ins> | <ins>**Override**</ins> | <ins>**Categories**</ins> | <ins>**Content**</ins> | <ins>**Prebuilt Image**</ins> | <ins>**x86_64**</ins> | <ins>**ARM64**</ins> | <ins>**Notes**</ins> |


**Legend**:
- **Component Name**: The name to use in the `RUNNER_COMPONENTS` build argument to enable the component.
- **Override**: Indicates if a local override script (from `docker-build/components/`) is used to adapt the installation for Docker or the ARM64 architecture.
  - `No`: No override script is used. The upstream script is executed as-is.
  - `ARM64`: The override script adapts the installation for the ARM64 architecture.
  - `Docker`: The override script adapts the installation for a containerized environment.
  - `Skip install`: The component is already installed during the prerequisites phase (`prereqs`) and is skipped if specified `RUNNER_COMPONENTS`.
- **Categories**: Functional categorie(s) associated with the component. This allows for grouped installations (e.g., `all-cloud`). See the [Categories List](#categories-list) for more details.
- **Prebuilt Image**: Specifies the smallest prebuilt image that includes this component. The `+` indicates that larger images also include it. The size order is: `base` < `essentials` < `medium` < `large` < `xlarge` < `all`. Category names (e.g., `cloud`) denote availability in thematic images in addition. See [docs/images.md](./images.md) for more information.
- **x86_64 / ARM64**: Component availability and testing status (in real workflows) by hardware architecture:
  - ✅ : Supported.
  - ❌ : Not supported or not available.
  - ⚠️ : Warning, see `Notes` column for details.
  - *Empty* : No test result reported in this architecture for now.

## Categories List

List of categories and their associated components (sorted alphabetically) :

- **browser**: `firefox`, `google-chrome`, `microsoft-edge`, `selenium`
- **build**: `bazel`, `clang`, `cmake`, `gcc-compilers`, `gfortran`, `ninja`, `packer`, `vcpkg`
- **cloud**: `aws-tools`, `azcopy`, `azure-cli`, `azure-devops-cli`, `bicep`, `google-cloud-cli`, `heroku`, `oc-cli`, `oras-cli`, `pulumi`
- **container**: `container-tools`, `docker`, `kubernetes-tools`
- **databases**: `mysql`, `postgresql`
- **dotnet**: `dotnetcore-sdk`
- **essentials**: `apt-common`, `git`, `git-lfs`, `github-cli`, `nodejs-lite`, `runner-package`, `yq`, `zstd`
- **haskell**: `haskell`
- **java**: `java-tools`, `kotlin`, `leiningen`, `sbt`
- **julia**: `julia`
- **lite**: `nodejs-lite` *(The lite version of a package is skipped if the full version is also requested or already installed)*
- **other**: `actions-cache`, `android-sdk`, `codeql-bundle`, `pipx-packages`
- **php**: `php`
- **python**: `miniconda`, `pipx-packages`, `pypy`, `python`
- **r**: `rlang`
- **ruby**: `ruby`
- **rust**: `rust`
- **system**: `apt-common`, `git`, `git-lfs`, `github-cli`, `homebrew`, `runner-package`
- **web**: `apache`, `nginx`

> [!TIP]
> Add `all-<category>` to `RUNNER_COMPONENTS` to install all components in that category.
For example, `all-java` will install `java-tools`, `kotlin`, `leiningen` and `sbt`.


## Components and categories declaration
All components and their associated categories are declared in the [docker-build/local-install/components.csv](../docker-build/local-install/components.csv) file.