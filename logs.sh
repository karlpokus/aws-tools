#!/bin/bash

# stream lambda logs
# note: headers are dumped to stderr to play nice with pipes

set -euo pipefail

# fuzzy search aws_profile

AWS_PROFILE=$(grep '\[profile' ~/.aws/config \
  | tr -d [] \
  | cut -d " " -f 2 \
  | peco)

test -z "${AWS_PROFILE}" && exit 0

source ./utils.sh

stderr "* Profile"
stderr "  ${AWS_PROFILE}"
stderr "* Logs"

# cache

CACHE_PATH="cache/logs/${AWS_PROFILE}"
logs_cache "${CACHE_PATH}"

if test ! -s "${CACHE_PATH}"; then
  stderr "  no logs available"
  exit 0
fi

# fuzzy search log group

LOG_GROUP=$(peco ${CACHE_PATH})

test -z "${LOG_GROUP}" && exit 0

stderr "  name: ${LOG_GROUP}"
stderr "  since: 5 min ago" # default is 10m
stderr "  following"

# stream

aws --profile "${AWS_PROFILE}" logs tail \
  "${LOG_GROUP}" --since 5m --format short --follow # --color on
