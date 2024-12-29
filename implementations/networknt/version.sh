#!/bin/bash

grep -E 'openapiprocessor = ".*"' implementations/openapiprocessor/gradle/libs.versions.toml | cut -d= -f2 | tr -d '" '
