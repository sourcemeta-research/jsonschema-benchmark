#!/bin/sh

set -o errexit
set -o nounset

# The JSON::Schema::Corvus::XS version the image built (the Dockerfile installs the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-pl-xs /app/corvus-version
