#! /bin/bash

if [ $# -eq 2 ] ; then
    SCHEMA=$1 INSTANCES=$2
else
    dir=$1
    SCHEMA="$dir/schema.json"
    INSTANCES="$dir/instances.jsonl"
fi

LOOP=100
NAME=$(basename $(dirname $SCHEMA))

function H
{
    echo "# $NAME" "$@" >&2
}

H schema: $SCHEMA
H instances: $INSTANCES

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
rm -f model.json model.out

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
        $jmc_opt -o ./model.out model.json
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
./model.out --jsonl "$INSTANCES" > model.txt
status=$?
let run_end=$(date +%s.%N | tr -d .)
let run_time=$(( $run_end - $run_start))

pass=$(grep PASS model.txt | wc -l)
fail=$(grep FAIL model.txt | wc -l)
err=$(grep ERROR model.txt | wc -l)

H results: pass=$pass fail=$fail error=$err
H run time: $(( $run_time / 1000 )) µs

# run again with internally measured validation time
./model.out --jsonschema-benchmark -T $LOOP "$INSTANCES" > time.txt

let validation_time=$(cat time.txt | cut -d, -f2)
H validation time: $(( $validation_time / 1000 )) µs

# timing & exit
echo $(cat time.txt| tr -d '\012'),$compile_time
exit $status
