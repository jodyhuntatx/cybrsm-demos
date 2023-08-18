#!/bin/bash

source demo-vars.sh.latam

main() {
  dump_platforms
  dump_group
  dump_accounts
}

dump_platforms() {
  echo "$ENV_TAG: Platforms ==========================="
  echo "  $ENV_TAG: Rotational Group Platform:"
  ./pcloud-cli.sh platform_details $rotationGroupPlatformId | jq .
  echo "-----------------------------------------------"
  echo "  $ENV_TAG: Target Account Platform:"
  ./pcloud-cli.sh platform_details $dualAccountPlatformId | jq .
  echo "==============================================="
}

dump_group() {
  groupJson=$(./pcloud-cli.sh safe_groups_get $SAFE_NAME)
  printf -v query '.[] | select(.GroupName=="%s").GroupID' $GROUP_NAME
  groupId=$(echo $groupJson | jq -r "$query")

  echo "$ENV_TAG: Rotational Group ===================="
  echo $groupJson | jq .
  if [[ "$groupId" != "" ]]; then
    echo "Group members:"
    ./pcloud-cli.sh safe_group_members_get $groupId | jq .
  fi
  echo "==============================================="
}

dump_accounts() {
  echo "$ENV_TAG: Dual Accounts ======================="
  echo "  $ENV_TAG: $ACCOUNT_NAME1:"
  ./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME1 | jq .
  echo "-----------------------------------------------"
  echo "  $ENV_TAG: $ACCOUNT_NAME2:"
  ./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME2 | jq .
  echo "==============================================="
}

main "$@"
