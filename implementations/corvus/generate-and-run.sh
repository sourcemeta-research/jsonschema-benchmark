#!/bin/bash

SCHEMA=$1
INSTANCES=$2

dialect=$(grep '$schema' $SCHEMA | head -1 | cut -d: -f2- | tr -d '", \n' | sed -nE 's_https?://json-schema.org/(.*)/schema#?_\1_p')
case "$dialect" in
  "draft-07")
    use_schema="Draft7" ;;
  "draft/2020-12")
    use_schema="Draft202012" ;;
esac

# Generate code for the schema validator
~/.dotnet/tools/generatejsonschematypes --rootNamespace JSB --rootPath='#' --useSchema "$use_schema" --outputPath /app --outputRootTypeName Schema --assertFormat False "$1" > /dev/null

cd /app

# Compile the generated validator
dotnet build --configuration=Release > /dev/null || exit 1

# Remove temporary generated files
find . -type f -name '*.cs' -not -name 'Program.cs' -delete

/app/bin/Release/net8.0/bench "$2"
exit $?
