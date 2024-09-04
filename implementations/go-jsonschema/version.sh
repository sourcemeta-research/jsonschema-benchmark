
#!/bin/bash

set -o errexit
set -o nounset

# Extract the version of the jsonschema module from go.mod
jsonschema_version=$(grep 'github.com/santhosh-tekuri/jsonschema' implementations/go-jsonschema/go.mod | sed -E 's/.*\/jsonschema\/v[0-9]+ v([0-9\.]+)/\1/')

# Output the version
echo "$jsonschema_version"
