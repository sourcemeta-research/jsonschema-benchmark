#!/bin/sh

set -o errexit
set -o nounset

docker run --rm --entrypoint /bin/sh jsonschema-benchmark/blaze -c "git -C /app/repo rev-parse --short=8 HEAD"