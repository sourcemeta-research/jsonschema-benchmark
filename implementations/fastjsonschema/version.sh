#!/bin/sh

set -o errexit
set -o nounset

# The version of fastjsonschema in uv.lock
grep -A 1 '^name = "fastjsonschema"$' implementations/fastjsonschema/uv.lock | tail -1 | cut -d= -f2 | tr -d '" '
