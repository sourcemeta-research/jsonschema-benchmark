#!/bin/sh

set -e

gradle run --quiet --args="$1 $2"
