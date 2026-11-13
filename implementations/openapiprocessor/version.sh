#!/bin/sh

set -o errexit
set -o nounset

# The version of io.openapiprocessor:json-schema-validator in pom.xml
sed -n '/<artifactId>json-schema-validator<\/artifactId>/{n;s/.*<version>\(.*\)<\/version>.*/\1/p;}' implementations/openapiprocessor/pom.xml
