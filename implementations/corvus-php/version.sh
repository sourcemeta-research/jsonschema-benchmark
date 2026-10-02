#!/bin/sh

set -o errexit
set -o nounset

# The corvus_json_schema version the image built (the Dockerfile installs the latest release with PIE).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-php /app/corvus-version
