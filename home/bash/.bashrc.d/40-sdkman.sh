# Java and Maven from SDKMAN (~/.sdkman; versions in packages/sdkman.txt), without SDKMAN's own shell setup.
# Its usual setup sources a big script in every new shell, which you would feel as startup lag. Instead: each tool's
# `current` version goes on PATH and JAVA_HOME / MAVEN_HOME point at it (no programs started), and `sdk` loads SDKMAN
# the first time you type it. `sdk default java <version>` moves `current`, so new shells follow it.
[[ $- == *i* ]] || return 0

export SDKMAN_DIR="$HOME/.sdkman"
if [[ -d $SDKMAN_DIR/candidates ]]; then
    for __sdk_bin in "$SDKMAN_DIR"/candidates/*/current/bin; do
        [[ -d $__sdk_bin && :$PATH: != *":$__sdk_bin:"* ]] && PATH="$__sdk_bin:$PATH"
    done
    unset __sdk_bin
    [[ -d $SDKMAN_DIR/candidates/java/current ]] && export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
    [[ -d $SDKMAN_DIR/candidates/maven/current ]] && export MAVEN_HOME="$SDKMAN_DIR/candidates/maven/current"
fi

# `sdk` loads SDKMAN on first use, then runs as usual.
sdk() {
    unset -f sdk
    source "$SDKMAN_DIR/bin/sdkman-init.sh" && sdk "$@"
}
