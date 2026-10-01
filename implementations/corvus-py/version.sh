#!/bin/sh

set -o errexit
set -o nounset

# The corvus-json-schema version the image built (pyproject.toml takes the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-py /app/corvus-version
