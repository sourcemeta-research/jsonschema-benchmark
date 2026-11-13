#!/bin/sh

set -o errexit
set -o nounset

# The typed-json release build.md installs.
grep -o '@frawa/typed-json/releases/[0-9.]*' implementations/typed-json/build.md | cut -d/ -f4
