#!/bin/bash

# defaults
OPT_SINCE=5m
OPT_FOLLOW=
OPT_UPDATE_CACHE=

stderr() {
  echo "$@" 1>&2
}

fatal() {
  echo "ERROR: $1"
  exit 1
}

create_cache() {
  local file=$1
  aws --profile "${AWS_PROFILE}" logs describe-log-groups \
    --log-group-name-prefix /aws/lambda --max-items 500 \
    | jq -r .logGroups[].logGroupName > "${file}"
}

usage() {
  cat << EOF
fuzzy search aws lambda logs

USAGE

  $0 <options>

OPTIONS

  -f        follow
  -s <time> pull logs since <time> in format 1m|3h|5d|7w
            default ${OPT_SINCE}
  -u        update log_group local cache
  -h        show help

EOF
  exit 0
}

# parse options
while getopts ":s:fuh" o; do
  case "${o}" in
    f) OPT_FOLLOW=y ;;
    s) OPT_SINCE="${OPTARG}" ;;
    u) OPT_UPDATE_CACHE=y ;;
    h) usage ;;
    *) fatal "unknown argument: -${OPTARG}" ;;
  esac
done
shift $((OPTIND-1))

# fuzzy search profile
AWS_PROFILE=$(grep '\[profile' ~/.aws/config | tr -d [] | cut -d " " -f 2 | peco)
stderr "* using aws profile ${AWS_PROFILE}"

# log_group cache
mkdir -p log_group
LOG_GROUP_FILE="log_group/${AWS_PROFILE}"
if [ ! -f "${LOG_GROUP_FILE}" ] || [ "${OPT_UPDATE_CACHE}" == "y" ]; then
  stderr "* creating cache"
  create_cache "${LOG_GROUP_FILE}"
  stderr "* cache created"
fi

# fuzzy search log group
LOG_GROUP=$(peco ${LOG_GROUP_FILE})
stderr "* pulling logs from ${LOG_GROUP} since ${OPT_SINCE} ago"

TAIL_ARGS="--since $OPT_SINCE --format short"
if [ "${OPT_FOLLOW}" == "y" ]; then
  TAIL_ARGS="${TAIL_ARGS} --follow"
fi

# note: this works nicely to fail gracefully if sso session expired
aws --profile "${AWS_PROFILE}" logs tail "${LOG_GROUP}" ${TAIL_ARGS}
