#!/bin/sh

set -o errexit
set -o nounset

# The corvus_json_schema version the image built (the Dockerfile installs the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-rb /app/corvus-version
