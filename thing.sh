#!/bin/bash

# Pull all data for an aws iot core thing

set -euo pipefail

if test -z $1; then
  echo "error: missing arg thing"
  exit 1
fi

THING_NAME=$1
AWS_PROFILE=

# fuzzy search aws_profile

source ./utils.sh
fuzzy_profile
test -z "${AWS_PROFILE}" && exit 0

echo "* Profile"
echo "  ${AWS_PROFILE}"
echo "* Thing"
echo "  ${THING_NAME}"
echo "* Attributes"

aws --profile "${AWS_PROFILE}" iot describe-thing \
  --thing-name "${THING_NAME}" \
  | jq '.attributes'

echo "* Jobs"

aws --profile "${AWS_PROFILE}" iot list-job-executions-for-thing \
  --thing-name "${THING_NAME}" \
  | jq '.executionSummaries'

# TODO: add shadows count

echo "* Shadows"

SHADOWS=$(aws --profile "${AWS_PROFILE}" iot-data list-named-shadows-for-thing \
  --thing-name "${THING_NAME}" \
  | jq -r '.results[]')

# TODO: classic shadow

if test ! -z "${SHADOWS}"; then
  for shadow_name in ${SHADOWS}; do
    shadow_data=$(aws --profile "${AWS_PROFILE}" iot-data get-thing-shadow \
      --shadow-name "${shadow_name}" --thing-name "${THING_NAME}" /dev/stdout \
      | jq)
    ts=$(jq <<<"${shadow_data}" \
      | grep timestamp \
      | head -n 1 \
      | tr -s " " \
      | cut -d " " -f 3)
    t=$(date -d @"${ts}" -Is)
    echo "  ${shadow_name}: last updated ${t}"
  done
fi

# * Profile
#   <prof>
# * Thing
#   name: <name>
#   attributes:
# {}
