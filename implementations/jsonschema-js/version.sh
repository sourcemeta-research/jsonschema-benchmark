#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/jsonschema"].version' < implementations/jsonschema-js/package-lock.json
