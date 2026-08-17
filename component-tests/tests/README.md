# Custom component tests

Optional per-component test scripts, run against the finished image after
build by `component-tests/run-component-tests.sh`.

To add one, drop a `<component-name>.sh` here (matching the component name
in `docker-build/local-install/components.csv`), e.g.:

```bash
#!/bin/bash
set -euo pipefail
command -v docker
docker --version
```

A non-zero exit fails that component's test. This runs *in addition to*, not
instead of, the component's own Pester test replayed from its install
script's `invoke_tests` call (if it still has one) - custom scripts are for
components whose Pester test can't run here (no daemon at test time, etc.)
or that need coverage beyond what upstream already checks.
