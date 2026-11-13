#!/bin/sh

set -o errexit
set -o nounset

# The version of org.sjf4j:sjf4j-schema in pom.xml
sed -n '/<artifactId>sjf4j-schema<\/artifactId>/{n;s/.*<version>\(.*\)<\/version>.*/\1/p;}' implementations/sjf4j/pom.xml
