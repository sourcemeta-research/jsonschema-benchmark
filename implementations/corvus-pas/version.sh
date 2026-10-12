#!/bin/sh

set -o errexit
set -o nounset

# The Object Pascal package version the image built (the Dockerfile takes the latest pas-v release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-pas /app/corvus-version
