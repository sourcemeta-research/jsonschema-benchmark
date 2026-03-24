#! /bin/env python

import argparse
import json
import logging
import sys
import time

import schema

def jsonschema_benchmark():
    """Run JSON Schema Benchmark on a an instances files"""

    logging.basicConfig()
    log = logging.getLogger("jsb")

    ap = argparse.ArgumentParser()
    ap.add_argument("--debug", action="store_true", help="set debug")
    ap.add_argument("--clock", "-C", default="r", help="set clock")
    ap.add_argument("values", nargs="*", help="JSONL files")
    args = ap.parse_args()

    log.setLevel(logging.DEBUG if args.debug else logging.INFO)

    clock: int
    if args.clock in ("r", "realtime"):
        clock = time.CLOCK_REALTIME
    elif args.clock in ("m", "monotonic"):
        clock = time.CLOCK_MONOTONIC
    elif args.clock in ("p", "process"):
        clock = time.CLOCK_PROCESS_CPUTIME_ID
    elif args.clock in ("t", "thread"):
        clock = time.CLOCK_THREAD_CPUTIME_ID
    else:
        raise Exception(f"unexpected clock spec: {args.clock}")

    errors = 0
    schema.check_model_init()
    # validator for root model
    checker = schema.check_model_fun("")

    # load all files into values
    values = []
    for fn in args.values:
        log.debug(f"considering file {fn}")

        # load jsonl data
        with open(fn) as f:
            values += [json.loads(r) for r in f]

    # overhead estimation in µs
    count = 0
    overhead_start = time.clock_gettime(clock)
    for v in values:
        count += 1
    overhead_delay = 1_000_000.0 * (time.clock_gettime(clock) - overhead_start)

    # cold run in µs
    cold_start = time.clock_gettime(clock)
    for v in values:
        if not checker(v, None, None):
            errors += 1
    cold_delay = 1_000_000.0 * (time.clock_gettime(clock) - cold_start)
    log.debug(f"cold delay: {cold_delay:.03f} µs")

    # warmup runs to trigger a potential JIT?
    warmup = min(1000, 1 + int(10_000_000.0 / cold_delay))
    log.debug(f"warmup loop: {warmup}")
    while warmup > 0:
        for v in values:
            checker(v, None, None)
        warmup -= 1

    # warm run in µs
    start = time.clock_gettime(clock)
    for v in values:
        checker(v, None, None)
    delay = 1_000_000.0 * (time.clock_gettime(clock) - start)

    # result for humans
    print(f"py validation: pass={len(values) - errors} fail={errors} "
          f"{delay:.03f} µs [{overhead_delay:.03f} µs]", file=sys.stderr)

    # cold-run-ns,warm-run-ns
    print(f"{int(1000 * cold_delay + 0.5)},{int(1000 * delay + 0.5)}")

    schema.check_model_free()
    sys.exit(1 if errors else 0)

if __name__ == "__main__":
    jsonschema_benchmark()
