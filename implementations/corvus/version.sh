#!/bin/sh

set -o errexit
set -o nounset

grep 'Include="Corvus.Text.Json"' implementations/corvus/bench.csproj | tr ' ' '\n' | grep Version | cut -d= -f2 | tr -d '"'
