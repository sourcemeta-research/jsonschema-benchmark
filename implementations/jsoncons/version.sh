#!/bin/sh

set -o errexit
set -o nounset

docker run --rm --entrypoint /bin/sh jsonschema-benchmark/jsoncons -c "cat /app/build/vcpkg_installed/x64-linux/include/jsoncons/config/version.hpp" \
  | grep -E '^#define JSONCONS_VERSION_(MAJOR|MINOR|PATCH)' \
  | cut -d' ' -f3 | tr '\n' '.' | sed 's/^/v/;s/\.$/\n/'
