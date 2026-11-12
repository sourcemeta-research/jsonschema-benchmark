#!/bin/sh

set -o errexit
set -o nounset

# The version of dev.harrel:json-schema in pom.xml
sed -n '/<artifactId>json-schema<\/artifactId>/{n;s/.*<version>\(.*\)<\/version>.*/\1/p;}' implementations/harrel-json-schema/pom.xml
