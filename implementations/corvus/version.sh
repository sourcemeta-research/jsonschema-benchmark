#!/bin/sh

set -o errexit
set -o nounset

grep -Eo '\--version .*$' implementations/corvus/Dockerfile | cut -d' ' -f2
