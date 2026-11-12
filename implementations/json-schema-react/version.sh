#!/bin/sh

set -o errexit
set -o nounset

# The version of io.github.georgeakulov:json-schema in pom.xml
sed -n '/<artifactId>json-schema<\/artifactId>/{n;s/.*<version>\(.*\)<\/version>.*/\1/p;}' implementations/json-schema-react/pom.xml
