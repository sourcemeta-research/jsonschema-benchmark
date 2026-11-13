#!/bin/sh

set -o errexit
set -o nounset

grep -Eo ':jsonschex, "([^"]+)"' implementations/jsonschex/mix.lock | cut -d, -f2 | tr -d ' "'
