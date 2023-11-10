#!/bin/bash

# AWS dynamodb operations

set -euo pipefail

OP=$1
KEY=${2:-}
TYPE=${3:-}
VALUE=${4:-}
export AWS_PROFILE=

# fuzzy search aws_profile

source ./utils.sh
fuzzy_profile
test -z "${AWS_PROFILE}" && exit 0

header Profile
body $AWS_PROFILE
header Table

# cache

CACHE_PATH="cache/table/${AWS_PROFILE}"
table_cache "${CACHE_PATH}"

# fuzzy search table

TABLE=$(peco ${CACHE_PATH})

test -z "${TABLE}" && exit 0

body $TABLE

if test $OP = "scan"; then
	aws dynamodb scan \
		--table-name $TABLE
	exit 0
fi

aws dynamodb "${OP}-item" \
	--table-name $TABLE \
	--key {\"$KEY\":{\"$TYPE\":\"$VALUE\"}}
