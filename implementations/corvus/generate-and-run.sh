#!/bin/bash

SCHEMA=$1
INSTANCES=$2

~/.dotnet/tools/generatejsonschematypes --rootNamespace JSB --rootPath='#' --useSchema Draft4 --outputPath /app --assertFormat false "$1" > /dev/null

cd app
dotnet build --configuration=Release > /dev/null || exit 1
rm -f Schema*.cs
/app/bin/Release/net8.0/bench "$2"
exit $?
