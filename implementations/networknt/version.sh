#!/bin/bash

grep -E 'networknt = ".*"' implementations/networknt/gradle/libs.versions.toml | cut -d= -f2 | tr -d '" '
