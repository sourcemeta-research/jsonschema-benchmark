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
    validator = Validator(schema)

    start = time.time_ns()
    for instance in instances:
        validator.is_valid(instance)
    end = time.time_ns()

    print(end - start)
