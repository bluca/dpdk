#!/bin/bash -xe

function on_error() {
    FILES_TO_PRINT=( "build/meson-logs/testlog.txt" "build/.ninja_log" "build/meson-logs/meson-log.txt")

    for pr_file in "${FILES_TO_PRINT[@]}"; do
        if [ -e "$pr_file" ]; then
            cat "$pr_file"
        fi
    done
}
trap on_error ERR

NINJA_PREFIX=""
if [ -n "$SONAR" ]; then
    NINJA_PREFIX="build-wrapper-linux-x86-64 --out-dir $PWD/bw-output "
    # Sonarcloud can use git blame to pin-point when an issue was introduced
    git fetch --unshallow
fi

if [ "${AARCH64}" == "1" ]; then
    # convert the arch specifier
    OPTS="${OPTS} -DRTE_ARCH_64=1 --cross-file config/arm/arm64_armv8_linuxapp_gcc"
fi

OPTS="$OPTS --default-library=$DEF_LIB"
meson build --werror -Dexamples=all ${OPTS}
${NINJA_PREFIX} ninja -C build -j4

if [ -n "$SONAR" ]; then
    sonar-scanner -Dsonar.projectKey=bluca_dpdk \
        -Dsonar.projectName=DPDK \
        -Dsonar.projectVersion=1.0-SNAPSHOT \
        -Dsonar.links.homepage=https://github.com/bluca/dpdk \
        -Dsonar.links.ci=https://travis-ci.org/bluca/dpdk \
        -Dsonar.links.scm=https://github.com/bluca/dpdk \
        -Dsonar.links.issue=https://github.com/bluca/dpdk/issues \
        -Dsonar.sources=. \
        -Dsonar.cfamily.threads=4 \
        -Dsonar.cfamily.build-wrapper-output=$PWD/bw-output \
        -Dsonar.cfamily.gcov.reportsPath=.
fi
