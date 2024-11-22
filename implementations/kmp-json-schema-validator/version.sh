#!/bin/bash

grep -E 'validator = ".*"' implementations/kmp-json-schema-validator/gradle/libs.versions.toml | cut -d= -f2 | tr -d '" '
