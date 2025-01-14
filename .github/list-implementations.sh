#!/bin/bash

# Get a list of all implementations (with some potentially ignored)
all_impls=$(make NO_IGNORE=$NO_IGNORE list)

# Add implementations changed in the PR
if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
  git fetch origin $GITHUB_BASE_REF --depth 1
  pr_impls=$(git diff --name-only FETCH_HEAD..HEAD | grep '^implementations/' | cut -d/ -f2 | uniq)
fi

# Format as JSON like {"include": [{"impl" "foo"}, ...]}
echo -e "$all_impls\n$pr_impls" | grep -v '^$' | sed 's/ *$//' | sort -u | tr '\n' ' ' | sed 's/ $//;s/^/{"include":\[{"impl":"/;s/ /"}, {"impl":"/g;s/$/"}]}/'
