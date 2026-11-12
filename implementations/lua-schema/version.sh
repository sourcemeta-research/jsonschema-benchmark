#!/bin/sh

set -o errexit
set -o nounset

# The lua-schema rock the image installed (the Dockerfile installs the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/lua-schema /lua-schema-version
