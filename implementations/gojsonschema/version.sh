#!/bin/sh

set -o errexit
set -o nounset

# The version of gojsonschema in go.mod
grep 'github.com/xeipuuv/gojsonschema ' implementations/gojsonschema/go.mod | sed -E 's/.* v([0-9.]+).*/\1/'
