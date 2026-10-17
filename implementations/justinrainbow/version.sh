#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages[] | select(.name == "justinrainbow/json-schema") | .version' implementations/justinrainbow/composer.lock
