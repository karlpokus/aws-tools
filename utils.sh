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
    echo "  cache: miss"
    aws --profile "${AWS_PROFILE}" iam list-roles \
      --max-items 500 \
      | jq -r '.Roles[].RoleName' > "${cache_path}"
  else
    echo "  cache: hit"
  fi
}

logs_cache() {
  local cache_path=$1
  local cache_dir=$(dirname "${cache_path}")
  mkdir -p "${cache_dir}"
  if test ! -f "${cache_path}"; then
    echo "  cache: miss"
    aws --profile "${AWS_PROFILE}" logs describe-log-groups \
      --log-group-name-prefix /aws/lambda --max-items 500 \
      | jq -r '.logGroups[].logGroupName' > "${cache_path}"
  else
    echo "  cache: hit"
  fi
}

fuzzy_profile() {
  AWS_PROFILE=$(grep '\[profile' ~/.aws/config \
    | tr -d [] \
    | cut -d " " -f 2 \
    | peco)
}
