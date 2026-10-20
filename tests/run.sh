#!/bin/sh
# Local validation only; dependency installation remains finn's responsibility.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
compiler=${FINC:-finc}
mode=${1:-all}
optimization=${2:--O0}
if [ "$#" -gt 2 ]; then
    printf '%s\n' 'usage: sh tests/run.sh [all|check|test|example] [-O0|-O1|-O2|-O3]' >&2
    exit 2
fi
case "$mode" in all|check|test|example) ;; *) printf 'unknown task: %s\n' "$mode" >&2; exit 2 ;; esac
case "$optimization" in -O0|-O1|-O2|-O3) ;; *) printf 'unsupported optimization: %s\n' "$optimization" >&2; exit 2 ;; esac

compile() {
    if [ "${FIN_LIBS+x}" = x ]; then
        "$compiler" "$@" -I "$root/src" --fin-libs "$FIN_LIBS"
    else
        "$compiler" "$@" -I "$root/src"
    fi
}

if [ "$mode" = check ] || [ "$mode" = all ]; then
    compile "$root/src/PKG_NAME.fin"
    compile "$root/tests/test_PKG_NAME.fin"
    compile "$root/examples/basic.fin"
fi
if [ "$mode" = check ]; then
    exit 0
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/fin-package.XXXXXXXX")
cleanup() {
    status=$?
    trap - 0
    rm -rf -- "$work" || :
    exit "$status"
}
trap cleanup 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [ "$mode" = test ] || [ "$mode" = all ]; then
    compile "$root/tests/test_PKG_NAME.fin" "$optimization" -o "$work/tests"
    "$work/tests"
fi
if [ "$mode" = example ] || [ "$mode" = all ]; then
    compile "$root/examples/basic.fin" "$optimization" -o "$work/example"
    "$work/example"
fi
