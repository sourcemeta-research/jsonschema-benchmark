#!/bin/sh

set -o errexit
set -o nounset

# The corvusjsonschema version the image built (the Dockerfile installs the latest release from R-universe).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-r /app/corvus-version
