#!/bin/sh

set -o errexit
set -o nounset

# Extract the version of the package (boon) from Cargo.toml
jsonschema_version=$(grep -A 1 '^name = "jsonschema"$' uv.lock | tail -1 | cut -d= -f2 | tr -d '" ')

# Output the version
echo "$jsonschema_version"
