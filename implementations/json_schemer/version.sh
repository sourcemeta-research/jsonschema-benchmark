#!/bin/sh

set -o errexit
set -o nounset

# Extract the version of the package (json_schemer) from Gemfile.lock
json_schemer_version=$(perl -nle'print $& while m{(?<=json_schemer \().*(?=\))}g' implementations/json_schemer/Gemfile.lock)

# Output the version
echo "$json_schemer_version"
