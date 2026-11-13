#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/vscode-json-languageservice"].version' < implementations/vscode-json-languageservice/package-lock.json
