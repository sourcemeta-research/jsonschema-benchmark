#!/bin/sh

set -o errexit
set -o nounset

# The Corvus.Text.Json version the image restored (bench.csproj takes the latest stable release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus /app/corvus-version
