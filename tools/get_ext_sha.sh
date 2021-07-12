#!/bin/bash

# Retrieves SHA of a given extension of a given branch (if exists)
# and exits 1 on fail

EXT=$1
BRANCH=$2
SHA=$(git ls-remote https://gerrit.wikimedia.org/r/mediawiki/extensions/$EXT refs/heads/$BRANCH \
 | head -1 \
 | sed "s/\trefs.*//" \
 | tr -d '[:space:]' \
)

if [[ -z "$SHA" ]]; then
  echo "SHA not found!"
  exit 1
fi

echo "$SHA"
