#!/bin/bash

# Get a list of all implementations (with some potentially ignored)
all_impls=$(make NO_IGNORE=$NO_IGNORE list | sort)

# Add implementations changed in the PR
if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
  git fetch origin $GITHUB_BASE_REF --depth 1
  pr_impls=$(git diff --name-only FETCH_HEAD..HEAD | grep '^implementations/' | cut -d/ -f2 | sort -u)
fi

# Get all implementations that are modified by the PR
base_impls=$(comm -23 <(echo "$all_impls") <(echo "$pr_impls"))

# Format as JSON like {"include": [{"impl" "foo"}, ...]}
echo -n '{"include":['
(echo "$base_impls" | grep -v '^$' | while read impl; do
  echo -n '{"impl": "'$impl'", "skip_cache": false},'
done
echo "$pr_impls" | while read impl; do
  [ -z "$impl" ] || echo -n '{"impl": "'$impl'", "skip_cache": true},'
done) | sed 's/,$//' # Remove trailing comma
echo "]}"
