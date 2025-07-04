#! /bin/bash

# script parameters
if [ $# -eq 1 ] ; then
    dir=$1
    SCHEMA="$dir/schema-noformat.json"
    INSTANCES="$dir/instances.jsonl"
    BACKEND=C
    LOOP=100
elif [ $# -eq 2 ] ; then
    SCHEMA=$1 INSTANCES=$2 BACKEND=C LOOP=100
elif [ $# -eq 3 ] ; then
    SCHEMA=$1 INSTANCES=$2 BACKEND=$3 LOOP=100
elif [ $# -eq 4 ] ; then
    SCHEMA=$1 INSTANCES=$2 BACKEND=$3 LOOP=$4
else
    echo "unexpected parameters" >&2
    exit 2
fi

# backend configuration
case $BACKEND in
    C|c)
        bench=./model.out
        ;;
    PY|Py|Python|py|python)
        bench=./model.py
        ;;
    JS|js|javascript|JavaScript)
        bench=./model.js
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
H backend: $BACKEND
H loop: $LOOP

#
# SPECIAL CASE HANDLING
#
case $NAME in
    cspell|ui5-manifest)
        H uselessly re2 incompatible regex
        jmc_opt="-re pcre2"
        jsu_model_opt=
        ;;
    openapi)
        jmc_opt=
        jsu_model_opt="--no-id"
        ;;
    *)
        jmc_opt=
        jsu_model_opt=
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
jsu-simpler "$SCHEMA" | jsu-model --id --loose $jsu_model_opt > model.json
status=$?

if [ $status -eq 0 ] ; then
    # generate exec from model
    H compiling...
    jmc --loose-number -D JSONSCHEMA_BENCHMARK \
        --maps "https://json-model.org/models/ /json-model/models/" \
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

# one direct run to collect pass/fail
let run_start=$(date +%s.%N | tr -d .)
$bench --jsonl "$INSTANCES" > model.txt
status=$?
let run_end=$(date +%s.%N | tr -d .)
let run_time=$(( $run_end - $run_start))

pass=$(grep PASS model.txt | wc -l)
fail=$(grep FAIL model.txt | wc -l)
err=$(grep ERROR model.txt | wc -l)

H results: pass=$pass fail=$fail error=$err
H run time: $(( $run_time / 1000 )) µs

# run again with internally measured validation time
$bench --jsonschema-benchmark -T $LOOP "$INSTANCES" > time.txt

let validation_time=$(cat time.txt | cut -d, -f2)
H validation time: $(( $validation_time / 1000 )) µs

# timing & exit
echo $(cat time.txt| tr -d '\012'),$compile_time
exit $status
