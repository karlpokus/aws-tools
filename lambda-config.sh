#!/bin/bash

# pull lambda configuration

set -euo pipefail

AWS_PROFILE=

# fuzzy search aws_profile

source ./utils.sh
fuzzy_profile
test -z "${AWS_PROFILE}" && exit 0

stderr "* Profile"
stderr "  ${AWS_PROFILE}"
stderr "* Lambda config"

# cache
#
# NOTE! Use log group name as a temp solution
# and strip the slashes to get the lambda name

CACHE_PATH="cache/logs/${AWS_PROFILE}"
logs_cache "${CACHE_PATH}"

if test ! -s "${CACHE_PATH}"; then
  stderr "  no lambda names available"
  exit 0
fi

# fuzzy search log group

LOG_GROUP=$(peco ${CACHE_PATH})

test -z "${LOG_GROUP}" && exit 0

# strip slashes
LAMBDA_NAME=$(cut -d / -f 4 <<< "${LOG_GROUP}")

stderr "  name: ${LAMBDA_NAME}"

aws --profile "${AWS_PROFILE}" lambda get-function-configuration \
    --function-name "${LAMBDA_NAME}" \
    | jq
