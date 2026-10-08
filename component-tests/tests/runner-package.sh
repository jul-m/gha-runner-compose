#!/bin/bash
set -euo pipefail

# Extraction happens at container startup (entrypoint.sh), not at build time,
# so there's no run.sh/config.sh to check here - only the cached archive.

case "$(uname -m)" in
    x86_64|amd64) arch_short="x64" ;;
    aarch64|arm64) arch_short="arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

cache_dir="/opt/runner-cache"
pattern="actions-runner-linux-${arch_short}-*.tar.gz"

if [ ! -d "$cache_dir" ]; then
    echo "Cache directory not found: $cache_dir" >&2
    exit 1
fi

matches=("$cache_dir"/actions-runner-linux-"${arch_short}"-*.tar.gz)
if [ ! -e "${matches[0]}" ]; then
    echo "No cached runner archive matching '$pattern' in $cache_dir" >&2
    exit 1
fi

if [ "${#matches[@]}" -ne 1 ]; then
    echo "Expected exactly one cached runner archive, found ${#matches[@]}: ${matches[*]}" >&2
    exit 1
fi

archive="${matches[0]}"

# Capture the listing before grep'ing it - piping straight into `grep -q`
# lets grep close the pipe after its first match, which under `pipefail`
# turns tar's resulting SIGPIPE into a false failure even when run.sh is found.
listing=$(tar -tzf "$archive")
if ! grep -q 'run\.sh$' <<<"$listing"; then
    echo "Cached archive is corrupt or missing run.sh: $archive" >&2
    exit 1
fi

echo "Runner package cache OK: $archive"
