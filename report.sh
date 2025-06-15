#!/bin/sh

set -o errexit
set -o nounset

if [ $# -lt 1 ]
then
  echo "Usage: $0 <results...>" 1>&2
  exit 1
fi

echo "implementation,version,name,cold_ns,warm_ns,compile_ns,memory,exit_status"

for argument in "$@"
do
  IMPLEMENTATION="$(basename "$(dirname "$argument")")"
  EXAMPLE="$(basename "$argument")"
  VERSION="$("./implementations/$IMPLEMENTATION/version.sh")"
  while read OUTPUT; do
    echo "$IMPLEMENTATION,$VERSION,$EXAMPLE,$OUTPUT"
  done < "$argument"
done
