#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/ata-validator"].version' < implementations/ata-validator/package-lock.json
