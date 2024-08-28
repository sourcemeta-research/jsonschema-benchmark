#!/bin/sh

set -o errexit
set -o nounset

# Extract the version of the package (boon) from Cargo.toml
boon_version=$(grep '^boon' implementations/boon/Cargo.toml | sed -E 's/boon *= *"([0-9\.]+)"/\1/')

# Output the version
echo "$boon_version"
