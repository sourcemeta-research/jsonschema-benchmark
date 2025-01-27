import math
import json
import os
import pathlib
import sys
import time

import jsonschema

WARMUP_ITERATIONS = 1000
MAX_WARMUP_TIME = 1e9 * 10

if __name__ == "__main__":
    example_dir = pathlib.Path(sys.argv[1])
    schema = json.load(open(example_dir / "schema-noformat.json"))
    instances = [json.loads(doc) for doc in open(example_dir / "instances.jsonl").readlines()]

    Validator = jsonschema.validators.validator_for(schema)
    compile_start = time.time_ns()
    validator = Validator(schema)
    compile_end = time.time_ns()

    cold_start = time.time_ns()
    for instance in instances:
        validator.is_valid(instance)
    cold_end = time.time_ns()

    iterations = math.ceil(MAX_WARMUP_TIME / (cold_end - cold_start))
    for _ in range(min(iterations, WARMUP_ITERATIONS)):
        for instance in instances:
            validator.is_valid(instance)

    warm_start = time.time_ns()
    for instance in instances:
        validator.is_valid(instance)
    warm_end = time.time_ns()

    print((cold_end - cold_start), ",", (warm_end - warm_start), ",", (compile_end - compile_start), sep='')
