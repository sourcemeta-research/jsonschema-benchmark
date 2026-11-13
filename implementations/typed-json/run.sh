#!/bin/sh
# Unison has no call to exit with a status, so the benchmark fails with `bug`, and ucm reports that on standard
# output. Keep only the timing line on standard output, move the rest to standard error, and keep ucm's status.
out=$(ucm run.compiled /app/benchmark.uc "$@")
status=$?
printf '%s\n' "$out" | grep -E '^[0-9]+,[0-9]+,[0-9]+,[0-9]+$'
printf '%s\n' "$out" | grep -v -E '^[0-9]+,[0-9]+,[0-9]+,[0-9]+$' >&2
exit $status
