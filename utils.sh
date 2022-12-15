#!/bin/bash

stderr() {
  echo "$@" 1>&2
}

role_cache() {
  local cache_path=$1
  local cache_dir=$(dirname "${cache_path}")
  mkdir -p "${cache_dir}"
  stderr "* Cache"
  if test ! -f "${cache_path}"; then
    stderr "  miss"
    create_role_cache "${cache_path}"
    stderr "  created"
  else
    stderr "  hit"
  fi
}

create_role_cache() {
  local file=$1
  aws --profile "${AWS_PROFILE}" iam list-roles \
    --max-items 500 \
    | jq -r '.Roles[].RoleName' > "${file}"
}
