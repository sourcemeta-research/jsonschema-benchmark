#! /bin/bash

# script parameters
if [ $# -eq 1 ] ; then
    dir=$1
    SCHEMA="$dir/schema-noformat.json"
    INSTANCES="$dir/instances.jsonl"
    BACKEND=C
    LOOP=
elif [ $# -eq 2 ] ; then
    SCHEMA=$1 INSTANCES=$2 BACKEND=C LOOP=
elif [ $# -eq 3 ] ; then
    SCHEMA=$1 INSTANCES=$2 BACKEND=$3 LOOP=
elif [ $# -eq 4 ] ; then
    SCHEMA=$1 INSTANCES=$2 BACKEND=$3 LOOP=$4
else
    echo "unexpected parameters" >&2
    exit 2
fi

# backend configuration
case $BACKEND in
    C|c)
        backend=c
        bench=./model.out
        loop=1000
        ;;
    PY|Py|Python|py|python)
        backend=python
        bench=./model.py
        loop=100
        ;;
    PL|Perl|pl|perl)
        backend=perl
        bench=./model.pl
        loop=20
        ;;
    JS|js|javascript|JavaScript)
        backend=javascript
        bench=./model.js
        loop=200
        ;;
    *)
        echo "unexpected backend: $BACKEND" >&2
        exit 3
        ;;
esac

NAME=$(basename $(dirname $SCHEMA))
[ "$LOOP" ] || LOOP=$loop

function H
{
    echo "# $NAME" "$@" >&2
}

H schema: $SCHEMA
H instances: $INSTANCES
H backend: $backend
H loop: $LOOP

#
# SPECIAL CASE HANDLING
#

jmc_opt="--no-reporting" jsu_model_opt="--id --loose --no-fix"

case $NAME in
    cspell|ui5-manifest)
        H uselessly re2 incompatible regex
        if [ "$backend" = "c" ] ; then
            jmc_opt+=" -re pcre2"
        else
            jmc_opt+=" -re re"
        fi
        ;;
    openapi)
        # the benchmark model is NOT the real one
        jsu_model_opt+=" --no-id"
        ;;
    *)
        ;;
esac

source /venv/bin/activate
rm -f model.json $bench

#
# COMPILE
#
H schema size: $(stat -c '%s' "$SCHEMA")

let compile_start=$(date +%s.%N | tr -d .)

# generate model from schema, by id or strict conversion
H generating...
jsu-simpler "$SCHEMA" | jsu-model $jsu_model_opt > model.json
status=$?

if [ $status -eq 0 ] ; then
    # generate exec from model
    H compiling...
    jmc --loose-number -D JSONSCHEMA_BENCHMARK \
        --maps "https://json-model.org/models/ /app/json-model/models/" \
        $jmc_opt -o $bench model.json
    status=$?
fi

let compile_end=$(date +%s.%N | tr -d .)
let compile_time=$(( $compile_end - $compile_start))

H compile time: $(( $compile_time / 1000 )) µs
[ $status -ne 0 ] && exit $status

#
# BENCH
#
H benchmarking...
H instances size: $(cat "$INSTANCES" | wc -lc)

# one direct preliminary run to collect pass/fail/errors and status
let run_start=$(date +%s.%N | tr -d .)
$bench --jsonl "$INSTANCES" > model.txt
status=$?
let run_end=$(date +%s.%N | tr -d .)
let run_time=$(( $run_end - $run_start))

# get counts
njson=$(cat "$INSTANCES" | wc -l)
pass=$(grep PASS model.txt | wc -l)
fail=$(grep FAIL model.txt | wc -l)
err=$(grep ERROR model.txt | wc -l)

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
$bench --jsonschema-benchmark -T $LOOP "$INSTANCES" > time.txt
status2=$?

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
