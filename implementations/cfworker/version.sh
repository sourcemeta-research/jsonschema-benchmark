#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/@cfworker/json-schema"].version' < implementations/cfworker/package-lock.json
