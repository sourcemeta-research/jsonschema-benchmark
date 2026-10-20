#!/bin/sh

set -o errexit
set -o nounset

# The JSON::Schema::Corvus version the image built (the Dockerfile installs the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-pl /app/corvus-version
