"""The jsonschema-benchmark entry point for jschon, which supports 2019-09 and 2020-12 (not draft 7).

    validate.py <schema.json> <instances.jsonl>

Mirrors the other implementations: read the instance file, parse every instance into jschon's JSON (timed), compile
the schema (timed), validate every instance once cold, warm up, validate once more warm. Prints one line
"cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
"""

import json
import sys
import time

import jschon

WARMUP_ITERATIONS = 100
MAX_WARMUP_TIME = 10_000_000_000  # 10 seconds


def validate_all(validator, instances):
    valid = True
    for instance in instances:
        if not validator(instance):
            valid = False
    return valid


def main():
    if len(sys.argv) != 3:
        print("Usage: validate.py <schema> <instances>", file=sys.stderr)
        return 1
    with open(sys.argv[1], encoding="utf-8") as f:
        schema = json.load(f)
    with open(sys.argv[2], encoding="utf-8") as f:
        lines = [line for line in f.read().splitlines() if line]

    parse_start = time.perf_counter_ns()
    instances = [jschon.JSON.loads(line) for line in lines]
    parse = time.perf_counter_ns() - parse_start

    # The catalog holds the 2019-09 and 2020-12 metaschemas; a schema of another dialect fails to compile.
    compile_start = time.perf_counter_ns()
    jschon.create_catalog("2019-09", "2020-12")
    compiled = jschon.JSONSchema(schema)

    def validator(instance):
        return compiled.evaluate(instance).valid

    compile_ = time.perf_counter_ns() - compile_start

    cold_start = time.perf_counter_ns()
    valid = validate_all(validator, instances)
    cold = time.perf_counter_ns() - cold_start

    iterations = -(-MAX_WARMUP_TIME // max(cold, 1))
    for _ in range(min(iterations, WARMUP_ITERATIONS)):
        validate_all(validator, instances)

    warm_start = time.perf_counter_ns()
    validate_all(validator, instances)
    warm = time.perf_counter_ns() - warm_start

    print(f"{cold},{warm},{compile_},{parse}")
    return 0 if valid else 1


if __name__ == "__main__":
    sys.exit(main())
