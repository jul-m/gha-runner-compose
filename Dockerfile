ARG BASE_IMAGE=base

FROM ubuntu:24.04 AS base

ARG TARGETARCH

LABEL org.opencontainers.image.source=https://github.com/jul-m/gha-runner-compose

ARG IMAGE_VERSION="latest"
ARG RUNNER_INSTALL_DIR=/opt/actions-runner
ARG RUNNER_USER=runner
ARG RUNNER_WORKDIR=/home/${RUNNER_USER}/work

ENV RUNNER_INSTALL_DIR=${RUNNER_INSTALL_DIR}
ENV RUNNER_USER=${RUNNER_USER}
ENV RUNNER_WORKDIR=${RUNNER_WORKDIR}
ENV IMAGE_VERSION=${IMAGE_VERSION}
ENV DEBIAN_FRONTEND=noninteractive
ENV NONINTERACTIVE=1

# => Copy APT config to enable caching
COPY docker-assets/apt.conf.d /imagegeneration/docker-assets/apt.conf.d

# => Enable APT caching + install base build dependencies + create runner user/directories
RUN --mount=type=cache,target=/var/cache/apt,id=apt-cache-$TARGETARCH,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,id=apt-lists-cache-$TARGETARCH,sharing=locked \
    mv /etc/apt/apt.conf.d/docker-clean /imagegeneration/docker-assets/apt.conf.d/docker-clean.bak && \
    ln -s /imagegeneration/docker-assets/apt.conf.d/zz-force-apt-cache.conf /etc/apt/apt.conf.d/zz-force-apt-cache.conf && \
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl jq git tar gzip unzip libicu-dev libkrb5-3 libssl-dev libcurl4-openssl-dev procps \
        sudo gnupg lsb-release file wget iptables parallel rsync ssh zip python-is-python3 && \
    useradd -m -s /bin/bash ${RUNNER_USER} && \
    echo "${RUNNER_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-runner && chmod 440 /etc/sudoers.d/90-runner && \
    mkdir -p ${RUNNER_INSTALL_DIR} ${RUNNER_WORKDIR} && \
    chown -R ${RUNNER_USER}:${RUNNER_USER} ${RUNNER_INSTALL_DIR} ${RUNNER_WORKDIR}

# => Install prerequisites + optional components
COPY --chmod=777 --chown=root:${RUNNER_USER} docker-assets/from-upstream /imagegeneration
COPY --chmod=777 --chown=root:${RUNNER_USER} docker-build /imagegeneration/docker-build

RUN --mount=type=cache,target=/var/cache/gha-download-cache,id=gha-download-cache \
    --mount=type=cache,target=/var/lib/apt/lists,id=apt-lists-cache-$TARGETARCH,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,id=apt-cache-$TARGETARCH,sharing=locked \
    --mount=type=secret,id=GITHUB_TOKEN,required=false \
    bash -e "/imagegeneration/docker-build/local-install/install-prereqs.sh" && \
    bash -e "/imagegeneration/docker-build/local-install/clean-restore.sh"
# clean-restore.sh remove temp file + restore APT config (docker-clean + remove zz-force-apt-cache.conf)

# => Entrypoint
COPY docker-assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

## => Switch to user runner
WORKDIR $RUNNER_WORKDIR
USER $RUNNER_USER


##################################################
FROM ${BASE_IMAGE} AS runner-build

ARG TARGETARCH

# Comma separated list of runner components to install (e.g. "docker,containerd").
# Already installed components in $BASE_IMAGE will be skipped.
ARG RUNNER_COMPONENTS=""

# List of additional apt packages to install (comma separated)
ARG APT_PACKAGES=""

# List of additional PowerShell modules to install (comma separated)
ARG PWSH_MODULES=""

RUN --mount=type=cache,target=/var/cache/gha-download-cache,id=gha-download-cache \
    --mount=type=cache,target=/var/lib/apt/lists,id=apt-lists-cache-$TARGETARCH,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,id=apt-cache-$TARGETARCH,sharing=locked \
    --mount=type=secret,id=GITHUB_TOKEN,required=false \
    sudo mv /etc/apt/apt.conf.d/docker-clean /imagegeneration/docker-assets/apt.conf.d/docker-clean.bak && \
    sudo ln -s /imagegeneration/docker-assets/apt.conf.d/zz-force-apt-cache.conf /etc/apt/apt.conf.d/zz-force-apt-cache.conf && \
    sudo -E RUNNER_COMPONENTS="$RUNNER_COMPONENTS" APT_PACKAGES="$APT_PACKAGES" PWSH_MODULES="$PWSH_MODULES" \
        bash -e "/imagegeneration/docker-build/local-install/install-components.sh" && \
    sudo bash -e "/imagegeneration/docker-build/local-install/clean-restore.sh"
# clean-restore.sh remove temp file + restore APT config (docker-clean + remove zz-force-apt-cache.conf)
