#!/bin/sh

set -o errexit
set -o nounset

# The version in build.sbt
sed -n 's/^val rcCirceJsonVersion = "v\{0,1\}\([^"]*\)"$/\1/p' implementations/rc-circe-json-schema/build.sbt
