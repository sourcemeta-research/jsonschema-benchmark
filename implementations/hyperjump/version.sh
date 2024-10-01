#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/ajv"].version' < implementations/ajv/package-lock.json
