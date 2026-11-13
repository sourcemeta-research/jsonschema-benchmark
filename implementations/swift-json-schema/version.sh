#!/bin/sh

set -o errexit
set -o nounset

# The swift-json-schema version the image built (Package.swift takes the latest release).
docker run --rm --entrypoint cat jsonschema-benchmark/swift-json-schema /app/swift-json-schema-version
