#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages[] | select(.name == "opis/json-schema") | .version' implementations/opis/composer.lock
