#!/bin/sh

set -o errexit
set -o nounset

grep -Eo ':jsv, "([^"]+)"' implementations/jsv/mix.lock | cut -d, -f2 | tr -d ' "'
