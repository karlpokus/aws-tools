#!/bin/bash

stderr() {
  echo "$@" 1>&2
}

fatal() {
  echo "ERROR: $1"
  exit 1
}

role_cache() {
  local cache_path=$1
  local cache_dir=$(dirname "${cache_path}")
  mkdir -p "${cache_dir}"
  if test ! -f "${cache_path}"; then
    echo "cache: miss"
    aws --profile "${AWS_PROFILE}" iam list-roles \
      --max-items 1000 \
      | jq -r '.Roles[].RoleName' > "${cache_path}"
  else
    echo "cache: hit"
  fi
}

logs_cache() {
  local cache_path=$1
  local cache_dir=$(dirname "${cache_path}")
  mkdir -p "${cache_dir}"
  if test ! -f "${cache_path}"; then
    echo "cache: miss"
    aws --profile "${AWS_PROFILE}" logs describe-log-groups \
      --log-group-name-prefix /aws/lambda --max-items 1000 \
      | jq -r '.logGroups[].logGroupName' > "${cache_path}"
  else
    echo "cache: hit"
  fi
}

table_cache() {
  local cache_path=$1
  local cache_dir=$(dirname "${cache_path}")
  mkdir -p "${cache_dir}"
  if test ! -f "${cache_path}"; then
    echo "cache: miss"
    aws --profile "${AWS_PROFILE}" dynamodb list-tables \
      | jq -r '.TableNames[]' > "${cache_path}"
  else
    echo "cache: hit"
  fi
}

fuzzy_profile() {
  AWS_PROFILE=$(grep '\[profile' ~/.aws/config \
    | tr -d [] \
    | cut -d " " -f 2 \
    | peco)
}

aws_regions="us-east-2
us-east-1
us-west-1
us-west-2
af-south-1
ap-east-1
ap-south-2
ap-southeast-3
ap-south-1
ap-northeast-3
ap-northeast-2
ap-southeast-1
ap-southeast-2
ap-northeast-1
ca-central-1
eu-central-1
eu-west-1
eu-west-2
eu-south-1
eu-west-3
eu-south-2
eu-north-1
eu-central-2
me-south-1
me-central-1
sa-east-1
us-gov-east-1
us-gov-west-1"

fuzzy_region() {
  AWS_REGION=$(peco <<<"${aws_regions}")
}

header() {
  tput setaf 5
  tput bold
  echo $@
  tput sgr0
}

body() {
  echo $@
}
