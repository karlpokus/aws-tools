#!/bin/bash

stderr() {
  echo "$@" 1>&2
}

role_cache() {
  local cache_path=$1
  local cache_dir=$(dirname "${cache_path}")
  mkdir -p "${cache_dir}"
  if test ! -f "${cache_path}"; then
    stderr "  cache: miss"
    create_role_cache "${cache_path}"
  else
    stderr "  cache: hit"
  fi
}

create_role_cache() {
  local file=$1
  aws --profile "${AWS_PROFILE}" iam list-roles \
    --max-items 500 \
    | jq -r '.Roles[].RoleName' > "${file}"
}
