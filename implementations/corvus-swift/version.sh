#!/bin/sh

set -o errexit
set -o nounset

# The CorvusJsonSchema version the image built (Package.swift takes the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/corvus-swift /app/corvus-version
