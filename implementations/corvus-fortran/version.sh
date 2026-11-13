#!/bin/sh

set -o errexit
set -o nounset

# The Fortran binding's version the image built (the Dockerfile takes its latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-fortran /app/corvus-version
