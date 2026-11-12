#!/bin/sh

set -o errexit
set -o nounset

# The version in build.sbt
sed -n 's/^val jsonSchemaVersion = "v\{0,1\}\([^"]*\)"$/\1/p' implementations/scala-json-schema/build.sbt
