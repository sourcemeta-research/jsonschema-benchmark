#! /bin/sh
#
# JSON Schema Benchmark with JSU C
#

set -o errexit -o nounset

[ -f /app/.env ] && . /app/.env

appdir=$(dirname $0) name=$(basename $0)

msg()
{
    echo "# $name: $@" >&2
}

err()
{
    local status=$1
    shift
    msg "$@"
    exit $status
}

# script parameters
if [ $# -eq 0 ] || [ "$1" = "--help" -o "$1" = "-h" ] ; then
    echo "Usage: $0 ( --help | --version | directory | schema instances [ options ] )"
    exit 0
elif [ $1 = "--version" ] ; then
    echo "jsu $(jsu-compile --version) [$(cc --version|head -1|sed -e 's/ *(.*)//')]"
    exit 0
elif [ $# -eq 1 ] ; then
    dir=$1
    [ -d "$dir" ] || err 2 "not a directory: $dir"
    SCHEMA="$dir/schema-noformat.json"
    INSTANCES="$dir/instances.jsonl"
else
    SCHEMA=$1 INSTANCES=$2
    shift 2
fi

[ -f "$SCHEMA" ] || err 3 "schema not a file: $SCHEMA"
[ -f "$INSTANCES" ] || err 4 "instances not a file: $INSTANCES"

workdir=$(dirname $SCHEMA)

compile_start=$(date +%s%N)

jsu-compile \
    --quiet \
    --no-id --no-strict --no-fix --no-format --no-reporting --loose \
    -o "$workdir/schema.c" \
    "$SCHEMA" \
    -- \
    --quiet

cc \
    -D CHECK_FUNCTION_NAME=check_model \
    -D REGEX_ENGINE_RE2 \
    -I "$JSU_RUNTIME/c" \
    -I /usr/local/include \
    -I /usr/include \
    -L /usr/local/lib \
    -o "$workdir/schema.exe" \
    "$appdir/jsonschema_benchmark.c" \
    "$workdir/schema.c" \
    "$JSU_RUNTIME/c/json-model.c" \
    -l jansson \
    -l cre2

compile_end=$(date +%s%N)
compile_time=$(( $compile_end - $compile_start ))
msg "$SCHEMA compile time is $(( $compile_time / 1000 )) µs"

times=$("$workdir/schema.exe" "$INSTANCES")
echo "$times,$compile_time"
