#!/bin/sh

set -o errexit
set -o nounset

# The version of jschon in uv.lock
grep -A 1 '^name = "jschon"$' implementations/jschon/uv.lock | tail -1 | cut -d= -f2 | tr -d '" '
