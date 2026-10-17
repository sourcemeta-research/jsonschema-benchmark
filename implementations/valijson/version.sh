#!/bin/sh

set -o errexit
set -o nounset

# The valijson tag that CMakeLists.txt fetches
sed -n 's/^ *GIT_TAG v\(.*\)$/\1/p' implementations/valijson/CMakeLists.txt
