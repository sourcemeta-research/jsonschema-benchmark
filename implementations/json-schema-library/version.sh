#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/json-schema-library"].version' < implementations/json-schema-library/package-lock.json
