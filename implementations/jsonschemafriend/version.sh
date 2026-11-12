#!/bin/sh

set -o errexit
set -o nounset

# The version of net.jimblackler.jsonschemafriend:core in pom.xml
sed -n '/<artifactId>core<\/artifactId>/{n;s/.*<version>\(.*\)<\/version>.*/\1/p;}' implementations/jsonschemafriend/pom.xml
