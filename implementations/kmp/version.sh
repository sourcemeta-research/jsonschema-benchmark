#!/bin/bash

grep -E 'validator = ".*"' implementations/kmp/gradle/libs.versions.toml | cut -d= -f2 | tr -d '" '
