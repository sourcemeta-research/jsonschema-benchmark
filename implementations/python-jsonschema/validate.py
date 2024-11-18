import json
import os
import pathlib
import sys
import time

import jsonschema

if __name__ == "__main__":
    example_dir = pathlib.Path(sys.argv[1])
    schema = json.load(open(example_dir / "schema.json"))
    instances = [json.loads(doc) for doc in open(example_dir / "instances.jsonl").readlines()]

    Validator = jsonschema.validators.validator_for(schema)
    compile_start = time.time_ns()
    validator = Validator(schema)
    compile_end = time.time_ns()

    start = time.time_ns()
    valid = True
    for instance in instances:
        valid = valid and validator.is_valid(instance)
    end = time.time_ns()

    print((end - start), ",", (compile_end - compile_start), sep='')
    sys.exit(0 if valid else 1)
