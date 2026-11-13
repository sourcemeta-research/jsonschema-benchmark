#!/bin/sh

set -o errexit
set -o nounset

# The valijson release the Dockerfile installs.
grep -o 'VALIJSON_VERSION=v[0-9.]*' implementations/valijson/Dockerfile | cut -dv -f2
