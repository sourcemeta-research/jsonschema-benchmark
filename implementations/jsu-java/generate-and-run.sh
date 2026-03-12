#! /bin/bash
#
# Run
#
# Usage:
# - $0 backend directory
# - $0 backend schema instances [ loop ]
#
# Default loop is 1.
#

# NOTE this induces early exit on errors, hence shortcut many checks below
# comment out for debugging
set -o errexit -o nounset

test -f .env && source .env

# script parameters
if [ $# -eq 2 ] ; then
    BACKEND=$1 dir=$2
    SCHEMA="$dir/schema-noformat.json"
    INSTANCES="$dir/instances.jsonl"
    LOOP=1
elif [ $# -eq 3 ] ; then
    BACKEND=$1 SCHEMA=$2 INSTANCES=$3 LOOP=1
elif [ $# -eq 4 ] ; then
    BACKEND=$1 SCHEMA=$2 INSTANCES=$3 LOOP=$4
else
    echo "unexpected parameters" >&2
    exit 2
fi

# backend configuration
case $BACKEND in
    C|c)
        backend=c
        bench="$(dirname $SCHEMA)/schema.out"
        launch=$bench
        ;;
    PY|Py|Python|py|python)
        backend=python
        bench="$(dirname $SCHEMA)/schema.py"
        launch=$bench
        ;;
    PL|Perl|pl|perl)
        backend=perl
        bench="$(dirname $SCHEMA)/schema.pl"
        launch=$bench
        ;;
    JS|js|javascript|JavaScript)
        backend=javascript
        bench="$(dirname $SCHEMA)/schema.js"
        launch=$bench
        ;;
    JV|Java|java)
        backend=java
        CLASSPATH="$(dirname $SCHEMA):$CLASSPATH"
        bench="$(dirname $SCHEMA)/schema.class"
        launch="java schema -j GSON"
        ;;
    *)
        echo "unexpected backend: $BACKEND" >&2
        exit 3
        ;;
esac

NAME=$(basename $(dirname $SCHEMA))

function H
{
    echo "# $NAME" "$@" >&2
}

H schema: $SCHEMA
H instances: $INSTANCES
H backend: $backend
H loop: $LOOP
H bench: $bench

#
# COMPILER BINARY OPTIONS: -[-no]-foo
#
# --id: use native (if available) schema conversion
# --strict: reject/accept any odd-looking schema
# --fix: repair/keep common schema syntactic errors
# --format: compile/ignore formats
# --reporting: with/without reporting code
# --loose: loose numbers, whether 1.0 is an int and 42 is a float, or not
#
jsu_compile_opt="--quiet --no-id --no-strict --no-fix --no-format --no-reporting --loose"
jmc_backend_opt="--quiet"

rm -f $bench

#
# COMPILE
#
H schema size: $(stat -c '%s' "$SCHEMA")

let compile_start=$(date +%s%N)

H compiling...
# NOTE JSONSCHEMA_BENCHMARK adds benchmarking option --jsonschema-benchmark
# NOTE --maps is needed only under --id
# NOTE -D only affects the C backend, it adds the specific performance measure code
jsu-compile $jsu_compile_opt -o "$bench" "$SCHEMA" -- \
    $jmc_backend_opt \
    -D JSONSCHEMA_BENCHMARK \
    --maps "https://json-model.org/models/ /app/json-model/models/"
status=$?

let compile_end=$(date +%s%N)
let compile_time=$(( $compile_end - $compile_start ))

[ $status -ne 0 ] && {
  H compilation failed
  exit $status
}

H compile time: $(( $compile_time / 1000 )) µs

#
# BENCH
#
H benchmarking...
H instances size: $(cat "$INSTANCES" | wc -lc)

# one direct preliminary run to collect pass/fail/errors and status
let run_start=$(date +%s.%N | tr -d .)
$launch --jsonl "$INSTANCES" > schema.txt
status=$?
let run_end=$(date +%s.%N | tr -d .)
let run_time=$(( $run_end - $run_start))

# get counts
njson=$(cat "$INSTANCES" | wc -l)
pass=$(grep PASS schema.txt | wc -l)
fail=$(grep FAIL schema.txt | wc -l)
err=$(grep ERROR schema.txt | wc -l)

# recheck result consistency on apparent success
if [ $status -eq 0 ] ; then
    if [ $njson -ne $pass -o $fail -ne 0 -o $err -ne 0 ] ; then
        H FIXME inconsistent status and results
        status=1
    fi
fi

H results: pass=$pass fail=$fail error=$err
H run time: $(( $run_time / 1000 )) µs

# run again with internally measured validation time
# NOTE status is non-zero on any fail with --jsonschema-benchmark
$launch --jsonschema-benchmark -T $LOOP "$INSTANCES" > time.txt
status2=$?

H status2=$status2 out=$(cat time.txt)

# set status to non-zero on any failure at any stage
if [ $status -eq 0 -a $status2 -ne 0 ] ; then
    H FIXME inconsistent benchmarking run
    status=$status2
fi

# sanity checks
let cold_time=$(cut -d, -f1 < time.txt 2> /dev/null)
if [ "$cold_time" = "" ] ; then
    H FIXME missing cold time
    cold_time=0
    [ "$status" -ne 0 ] || status=1
fi

let validation_time=$(cut -d, -f2 < time.txt 2> /dev/null)
if [ "$validation_time" = "" ] ; then
    H FIXME missing validation time
    validation_time=0
    [ "$status" -ne 0 ] || status=1
else
    H validation time: $(( $validation_time / 1000 )) µs
fi

# show timings & exit
echo "$cold_time,$validation_time,$compile_time"
exit $status
