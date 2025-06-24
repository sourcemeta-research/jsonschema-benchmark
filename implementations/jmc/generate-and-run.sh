#! /bin/bash

SCHEMA=$1
INSTANCES=$2

LOOP=100
NAME=$(basename $(dirname $SCHEMA))

function H
{
    echo "# $NAME" "$@" >&2
}


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

let compile_start=$(date +%s.%N | tr -d .)

H generating...
# generate model from schema, by id or strict conversion
jsu-simpler "$SCHEMA" | jsu-model --id --loose $jsu_model_opt > model.json
status=$?

if [ $status -eq 0 ] ; then
    # generate exec from model
    H compiling...
    jmc --loose-number --maps "https://json-model.org/models/ /json-model/models/" \
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

let run_start=$(date +%s.%N | tr -d .)
./model.out --jsonl "$INSTANCES" > model.txt
status=$?
let run_end=$(date +%s.%N | tr -d .)
let run_time=$(( $run_end - $run_start))

H run time: $(( $run_time / 1000 )) µs

# run again with internally measured time
./model.out --jsonschema-benchmark -T $LOOP "$INSTANCES" > time.txt
let valid_time=$(cat time.txt)

H valid time: $valid_time µs

# summary
pass=$(grep PASS model.txt | wc -l)
fail=$(grep FAIL model.txt | wc -l)
err=$(grep ERROR model.txt | wc -l)
H pass=$pass fail=$fail error=$err

# timing & exit
echo $valid_time,$compile_time
exit $status
