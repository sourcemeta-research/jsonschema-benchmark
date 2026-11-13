#!/bin/sh

set -o errexit
set -o nounset

# The IRIS release the Dockerfile builds.
grep -o 'IRIS_VERSION=v[0-9.]*' implementations/iris/Dockerfile | cut -dv -f2
