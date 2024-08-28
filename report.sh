#!/bin/sh

set -o errexit
set -o nounset

if [ $# -lt 1 ]
then
  echo "Usage: $0 <results...>" 1>&2
  exit 1
fi

echo "implementation,version,name,nanoseconds"

for argument in "$@"
do
  IMPLEMENTATION="$(basename "$(dirname "$argument")")"
  EXAMPLE="$(basename "$argument")"
  NANOSECONDS="$(tr -d '\n\r' < "$argument")"
  VERSION="$("./implementations/$IMPLEMENTATION/version.sh")"
  echo "$IMPLEMENTATION,$VERSION,$EXAMPLE,$NANOSECONDS"
done
