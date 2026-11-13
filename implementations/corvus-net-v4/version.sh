#!/bin/sh

set -o errexit
set -o nounset

# The Corvus.Json.Validator version the image restored (bench.csproj takes the latest stable release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-net-v4 /app/corvus-version
