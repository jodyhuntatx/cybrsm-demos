#!/bin/bash

source env-vars.sh

ROTATIONAL_GROUP_PLATFORM_ID=RotationGroup-Default
GROUP_NAME=MySQL-AcctGroup
ACCOUNT_PLATFORM_ID=MySQL-Dual
SAFE_NAME=TestDualAccounts
ACCOUNT_NAME1=MySQL-DualAccts1
ACCOUNT_NAME2=MySQL-DualAccts2

main() {
  dump_platforms
  dump_group
  dump_accounts
}

dump_platforms() {
  echo "$ENV_TAG: Platforms ==========================="
  echo "  $ENV_TAG: Rotational Group Platform:"
  ./cybrvault-cli.sh platform_details $ROTATIONAL_GROUP_PLATFORM_ID | jq .
  echo "-----------------------------------------------"
  echo "  $ENV_TAG: Target Account Platform:"
  ./cybrvault-cli.sh platform_details $ACCOUNT_PLATFORM_ID | jq .
  echo "==============================================="
}

dump_group() {
  allSafeGroups=$(./cybrvault-cli.sh safe_groups_get $SAFE_NAME)
  printf -v query '.[] | select(.GroupName=="%s")' $GROUP_NAME
  groupJson=$(echo $allSafeGroups | jq -r "$query")
  groupId=$(echo $groupJson | jq -r .GroupID)

  echo "$ENV_TAG: Rotational Group ===================="
  echo $groupJson | jq .
  if [[ "$groupId" != "" ]]; then
    echo "Group members:"
    ./cybrvault-cli.sh safe_group_members_get $groupId | jq .
  fi
  echo "==============================================="
}

dump_accounts() {
  echo "$ENV_TAG: Dual Accounts ======================="
  echo "  $ENV_TAG: $ACCOUNT_NAME1:"
  ./cybrvault-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME1 | jq .
  echo "-----------------------------------------------"
  echo "  $ENV_TAG: $ACCOUNT_NAME2:"
  ./cybrvault-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME2 | jq .
  echo "==============================================="
}

main "$@"
