#!/bin/sh

set -o errexit
set -o nounset

# The jsonschema-rs version the image built (pyproject.toml takes the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/jsonschema-rs /app/jsonschema-rs-version
