#!/bin/bash

# Pull the shadow for an AWS IoT thing

set -euo pipefail

THING_NAME=$1
SHADOW_NAME=${2:-classic}
export AWS_PROFILE=

# fuzzy search aws_profile

source ./utils.sh
fuzzy_profile
test -z "${AWS_PROFILE}" && exit 0

echo "* Profile"
echo "  ${AWS_PROFILE}"
echo "* Thing"
echo "  ${THING_NAME}"
echo "* Shadow"
echo "  ${SHADOW_NAME}"

if test "${SHADOW_NAME}" = "classic"; then 
  aws iot-data get-thing-shadow \
    --thing-name "${THING_NAME}" /dev/stdout \
    | jq '.state'
else
  aws iot-data get-thing-shadow \
    --thing-name "${THING_NAME}" \
    --shadow-name "${SHADOW_NAME}" /dev/stdout \
    | jq '.state'
fi
