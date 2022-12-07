#!/bin/bash

# Show all permissions for an aws iam role
# including inline and/or attached

#AWS_PROFILE=$(grep '\[profile' ~/.aws/config | tr -d [] | cut -d " " -f 2 | peco)
AWS_PROFILE=$1

if test -z "${AWS_PROFILE}"; then
  echo "error: missing arg"
  exit 1
fi

# fuzzy search the role with peco

ROLE=$(aws --profile "${AWS_PROFILE}" iam list-roles \
  --max-items 500 \
  | jq -r '.Roles[].RoleName' \
  | peco)

test -z "${ROLE}" && exit 0

echo "* Role"
echo "  ${ROLE}"

# pull role data

ROLE_DATA=$(aws --profile "${AWS_PROFILE}" iam get-role \
  --role-name "${ROLE}")

test -z "${ROLE_DATA}" && exit 0

# filter out assume policy

ASSUME_POLICY=$(jq -C '.Role.AssumeRolePolicyDocument.Statement' <<<"${ROLE_DATA}")
LAST_USED=$(jq -r '.Role.RoleLastUsed.LastUsedDate' <<<"${ROLE_DATA}")

echo "* AssumeRolePolicyDocument"
echo "  last used: ${LAST_USED}"
echo "${ASSUME_POLICY}"

# try pulling inline policies

INLINE_POLICIES=$(aws --profile "${AWS_PROFILE}" iam list-role-policies \
  --role-name "${ROLE}")

INLINE_POLICIES_LENGTH=$(jq '.PolicyNames | length' <<<"${INLINE_POLICIES}")

echo "* Inline Policies count: ${INLINE_POLICIES_LENGTH}"

if test "${INLINE_POLICIES_LENGTH}" -gt 0; then
  # assume only one inline policy
  INLINE_POLICY_NAME=$(jq -r '.PolicyNames[0]' <<<"${INLINE_POLICIES}")
  echo "* Inline Policy name: ${INLINE_POLICY_NAME}"
  aws --profile "${AWS_PROFILE}" iam get-role-policy \
    --role-name "${ROLE}" \
    --policy-name "${INLINE_POLICY_NAME}" \
    | jq '.PolicyDocument.Statement'
fi

# try pulling attached policies

ATTACHED_POLICIES=$(aws --profile "${AWS_PROFILE}" iam list-attached-role-policies \
  --role-name "${ROLE}")

ATTACHED_POLICIES_LENGTH=$(jq '.AttachedPolicies | length' <<<"${ATTACHED_POLICIES}")

echo "* Attached Policies count: ${ATTACHED_POLICIES_LENGTH}"

test "${ATTACHED_POLICIES_LENGTH}" -eq 0 && exit 0

# assume only one attached policy
ATTACHED_POLICY_ARN=$(jq -r '.AttachedPolicies[].PolicyArn' <<<"${ATTACHED_POLICIES}")

echo "* Attached Policy arn: ${ATTACHED_POLICY_ARN}"

VERSION=$(aws --profile "${AWS_PROFILE}" iam get-policy \
  --policy-arn "${ATTACHED_POLICY_ARN}" \
  | jq -r .Policy.DefaultVersionId)

aws --profile "${AWS_PROFILE}" iam get-policy-version \
  --policy-arn "${ATTACHED_POLICY_ARN}" \
  --version-id "${VERSION}" \
  | jq '.PolicyVersion.Document.Statement'
