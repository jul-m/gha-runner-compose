#!/bin/bash
set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/HelloWorld.java" <<'EOF'
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("hello from " + System.getProperty("java.version"));
    }
}
EOF

cd "$WORKDIR"
javac HelloWorld.java
[ -f HelloWorld.class ]
[[ "$(java HelloWorld)" == "hello from "* ]]

# every installed JDK version must be independently usable via its own JAVA_HOME_<version>_X64,
# not just the default one wired up to JAVA_HOME
for env_var in $(compgen -v | grep -E '^JAVA_HOME_[0-9]+_X64$'); do
    java_home_versioned="${!env_var}"
    [ -x "$java_home_versioned/bin/javac" ]
    "$java_home_versioned/bin/javac" HelloWorld.java -d "$WORKDIR/out-$env_var"
    "$java_home_versioned/bin/java" -cp "$WORKDIR/out-$env_var" HelloWorld
done

mvn --version
ant -version
gradle --version
