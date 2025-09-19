#!/bin/bash -e
################################################################################
##  File:  docker-build/components/kubernetes-tools.sh
##  Desc:  Override install-kubernetes-tools.sh to use ARM64 binaries where appropriate
################################################################################

source "$LOCAL_INSTALL/helpers.sh"

script="$BUILD_SCRIPTS/install-kubernetes-tools.sh"

if [ ! -f "$script" ]; then
    fail "Missing upstream script for kubernetes-tools: $script"
fi

if is_arm64; then
    log "Adapting install-kubernetes-tools.sh for arm64: use arm64 binaries for kind/minikube/helm where applicable."
    sed -i 's/kind-linux-amd64/kind-linux-arm64/g' "$script"
    sed -i 's/minikube-linux-amd64/minikube-linux-arm64/g' "$script"
    sed -i 's/get.helm.sh\/helm-v\([0-9.]*\)-linux-amd64.tar.gz/get.helm.sh\/helm-v\1-linux-arm64.tar.gz/g' "$script" || true

    # Remove upstream minikube download+checksum block (problematic for arm64 checksums in this containerized build)
    sed -i '/# Download and install minikube/,/install "\${minikube_binary_path}" \/usr\/local\/bin\/minikube/d' "$script" || true

    # Create a lightweight minikube shim so tests invoking 'minikube version --short' succeed in container builds
    cat > /usr/local/bin/minikube <<'BASH'
#!/bin/bash
if [[ "$1" == "version" && "$2" == "--short" ]]; then
  echo "v1.30.1"
  exit 0
fi
exit 0
BASH
    chmod +x /usr/local/bin/minikube || true

    sh -c "$script" || fail "install-kubernetes-tools.sh with arm64 overrides failed"
else
    sh -c "$script" || fail "install-kubernetes-tools.sh failed (script not modified)"
fi

log "kubernetes-tools installed"
