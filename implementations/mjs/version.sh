#!/bin/sh

set -o errexit
set -o nounset

grep '^val mjsVersion =' implementations/mjs/build.sbt | cut -d= -f2 | tr -d '" '
