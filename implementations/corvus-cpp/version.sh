#!/bin/sh

set -o errexit
set -o nounset

# The C library version the image built against (the Dockerfile takes the latest capi-v release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-cpp /app/corvus-version
