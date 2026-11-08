#!/bin/sh

set -o errexit
set -o nounset

jq --raw-output '.packages["node_modules/@hyperjump/json-schema"].version' < implementations/hyperjump/package-lock.json
