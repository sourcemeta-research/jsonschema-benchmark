#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/@theflashlabs/ajv-plus"].version' < implementations/ajv-plus/package-lock.json
