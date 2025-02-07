#!/bin/sh

set -o errexit
set -o nounset

grep 'Include="JsonSchema.Net"' implementations/jsdotnet/bench.csproj | tr ' ' '\n' | grep Version | cut -d= -f2 | tr -d '"'
