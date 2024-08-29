#!/bin/sh

set -o errexit
set -o nounset

docker run --rm --entrypoint /bin/sh jsonschema-benchmark/jsontoolkit -c "git -C /app/repo rev-parse --short=8 HEAD"
