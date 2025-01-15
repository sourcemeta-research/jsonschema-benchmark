#!/bin/bash

grep -E 'jsonSchema = ".*"' implementations/harrel-json-schema/gradle/libs.versions.toml | cut -d= -f2 | tr -d '" '
