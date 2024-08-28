#!/bin/sh

set -o errexit
set -o nounset

git -C dist/temp/jsontoolkit/repo rev-parse --short=8 HEAD
