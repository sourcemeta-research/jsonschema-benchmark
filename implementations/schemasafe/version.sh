#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/@exodus/schemasafe"].version' < implementations/schemasafe/package-lock.json
