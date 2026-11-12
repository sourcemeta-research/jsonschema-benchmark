#!/bin/sh

set -o errexit
set -o nounset

# The version of luposlip/json-schema in project.clj
sed -n 's|.*\[luposlip/json-schema "\([^"]*\)"\].*|\1|p' implementations/clojure-json-schema/project.clj
