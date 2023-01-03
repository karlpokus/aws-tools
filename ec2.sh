#!/bin/bash

# start, stop, restart or reboot an ec2 instance and wait until completion
# note: rebooting is instant and will never mark target as unavailable

set -euo pipefail

AWS_PROFILE=
AWS_REGION=

# fuzzy search aws_profile and region

source ./utils.sh

fuzzy_profile
test -z "${AWS_PROFILE}" && exit 0

fuzzy_region
test -z "${AWS_REGION}" && exit 0

echo "* Profile"
echo "  ${AWS_PROFILE}"
echo "* Region"
echo "  ${AWS_REGION}"

# fuzze search instance

# state id name
INSTANCE_DATA=$(aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" ec2 describe-instances \
  | jq -r '.Reservations[].Instances[] | "\(.State.Name) \(.InstanceId) \(.Tags[] | select(.Key=="Name") | .Value)"' \
  | peco)

test -z "${INSTANCE_DATA}" && exit 0

INSTANCE_NAME=$(cut -d " " -f 3 <<<"${INSTANCE_DATA}")
INSTANCE_ID=$(cut -d " " -f 2 <<<"${INSTANCE_DATA}")
INSTANCE_STATE=$(cut -d " " -f 1 <<<"${INSTANCE_DATA}")

echo "* Instance"
echo "  ${INSTANCE_NAME}"
echo "  ${INSTANCE_ID}"
echo "  ${INSTANCE_STATE}"
echo "* Operation"

# fuzzy search operation

OPERATION_LIST="start
stop
restart
reboot_"

OPERATION=$(peco <<<"${OPERATION_LIST}")

test -z "${OPERATION}" && exit 0
echo "  ${OPERATION}"
echo "  waiting for completion"

start() {
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" ec2 start-instances \
    --instance-ids "${INSTANCE_ID}" \
    | jq
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" ec2 wait instance-status-ok \
    --instance-ids "${INSTANCE_ID}"
}

stop() {
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" ec2 stop-instances \
    --instance-ids "${INSTANCE_ID}" \
    | jq
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" ec2 wait instance-stopped \
    --instance-ids "${INSTANCE_ID}"
}

restart() {
  stop
  start
}

reboot_() {
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" ec2 reboot-instances \
    --instance-ids "${INSTANCE_ID}"
  aws --profile "${AWS_PROFILE}" --region "${AWS_REGION}" ec2 wait instance-status-ok \
    --instance-ids "${INSTANCE_ID}"
}

# execute

$OPERATION

echo "  ok"

# Maybe run describe-instance-status | jq at the end
# btw .InstanceStatuses[].InstanceState.Name is "running" and never changes during restart
# but .InstanceStatuses[].InstanceStatus.Status and .SystemStatus.Status moves from
# "ok" to "initializing" back to "ok"
