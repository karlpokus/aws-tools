#!/bin/bash

# Show ALL permissions for a particular aws iam role
# including inline and/or attached policies

set -euo pipefail

AWS_PROFILE=

source ./utils.sh

# fuzzy search aws_profile

fuzzy_profile
test -z "${AWS_PROFILE}" && exit 0

header Profile
body $AWS_PROFILE
header Role

# cache

CACHE_PATH="cache/role/${AWS_PROFILE}"
role_cache "${CACHE_PATH}"

# fuzzy search role

ROLE=$(peco "${CACHE_PATH}")

test -z "${ROLE}" && exit 0

body $ROLE

# pull role data

ROLE_DATA=$(aws --profile "${AWS_PROFILE}" iam get-role \
  --role-name "${ROLE}")

test -z "${ROLE_DATA}" && exit 0

# filter out assume policy

ASSUME_POLICY=$(jq -C '.Role.AssumeRolePolicyDocument.Statement' <<<"${ROLE_DATA}")
LAST_USED=$(jq -r '.Role.RoleLastUsed.LastUsedDate' <<<"${ROLE_DATA}")

body "last used: ${LAST_USED}"
body "AssumeRolePolicyDocument:"
echo "${ASSUME_POLICY}"

# try pulling inline policies

INLINE_POLICIES=$(aws --profile "${AWS_PROFILE}" iam list-role-policies \
  --role-name "${ROLE}")

INLINE_POLICIES_LENGTH=$(jq '.PolicyNames | length' <<<"${INLINE_POLICIES}")

header "Inline Policies: ${INLINE_POLICIES_LENGTH}"

if test "${INLINE_POLICIES_LENGTH}" -gt 0; then
  for inline_policy_name in $(jq -r '.PolicyNames[]' <<<"${INLINE_POLICIES}"); do
    echo "  policy name: ${inline_policy_name}"
    aws --profile "${AWS_PROFILE}" iam get-role-policy \
      --role-name "${ROLE}" \
      --policy-name "${inline_policy_name}" \
      | jq '.PolicyDocument.Statement'
  done
fi

# try pulling attached policies

ATTACHED_POLICIES=$(aws --profile "${AWS_PROFILE}" iam list-attached-role-policies \
  --role-name "${ROLE}")

ATTACHED_POLICIES_LENGTH=$(jq '.AttachedPolicies | length' <<<"${ATTACHED_POLICIES}")

header "Attached Policies: ${ATTACHED_POLICIES_LENGTH}"

test "${ATTACHED_POLICIES_LENGTH}" -eq 0 && exit 0

for attached_policy_arn in $(jq -r '.AttachedPolicies[].PolicyArn' <<<"${ATTACHED_POLICIES}"); do
  body "  policy arn: ${attached_policy_arn}"
  version=$(aws --profile "${AWS_PROFILE}" iam get-policy \
    --policy-arn "${attached_policy_arn}" \
    | jq -r .Policy.DefaultVersionId)
  aws --profile "${AWS_PROFILE}" iam get-policy-version \
    --policy-arn "${attached_policy_arn}" \
    --version-id "${version}" \
    | jq '.PolicyVersion.Document.Statement'
done
