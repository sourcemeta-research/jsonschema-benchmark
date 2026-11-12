#!/bin/sh

set -o errexit
set -o nounset

# The JSON::Schema::Modern version the image built (the Dockerfile installs the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/json-schema-modern /app/jsm-version
