#!/bin/sh

set -o errexit
set -o nounset

if [ $# -lt 1 ]
then
  echo "Usage: $0 <results...>" 1>&2
  exit 1
fi

echo "implementation,version,name,cold_ns,warm_ns,compile_ns,exit_status"

for argument in "$@"
do
  IMPLEMENTATION="$(basename "$(dirname "$argument")")"
  EXAMPLE="$(basename "$argument")"
  OUTPUT="$(tr -d '\n\r' < "$argument")"
  VERSION="$("./implementations/$IMPLEMENTATION/version.sh")"
  echo "$IMPLEMENTATION,$VERSION,$EXAMPLE,$OUTPUT"
done
