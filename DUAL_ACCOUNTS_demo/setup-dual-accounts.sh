#!/bin/bash

source ./demo-vars.sh

main() {
#  create_safe
#  create_accounts
#  get_accounts
  create_account_rotationalgroup
  add_accounts_to_account_rotationalgroup
  get_group_info
}

##################################################
# Safe - Safe must have a CPM assigned for the subsequent commands to succeed
create_safe() {
  ./pcloud-cli.sh safe_create $SAFE_NAME "Safe for testing dual accounts" $CPM_NAME
  ./pcloud-cli.sh safe_admin_add $SAFE_NAME $SAFE_ADMIN
}

##################################################
# Create two accounts in the safe, using the appropriate dual-account platform.
create_accounts() {
  ./pcloud-cli.sh account_create_db_dual $SAFE_NAME $PLATFORM_ID $ACCOUNT_NAME1 testuser1 Cyberark1 192.168.68.122 petclinic 3306 MySQL-DA 1 Active
  ./pcloud-cli.sh account_create_db_dual $SAFE_NAME $PLATFORM_ID $ACCOUNT_NAME2 testuser2 Cyberark1 192.168.68.122 petclinic 3306 MySQL-DA 2 Inactive
}

##################################################
get_accounts() {
  ./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME2
  ./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME2
}

##################################################
# Create an account group for the safe, using the appropriate Rotational Group platform.
create_account_rotationalgroup() {
  ./pcloud-cli.sh safe_group_create $SAFE_NAME $GROUP_NAME $GROUP_PLATFORM_ID
}

##################################################
# Add the two accounts to the group. Sadly this must be done using the numeric IDs, not their names
add_accounts_to_account_rotationalgroup() {
  printf -v query '.[] | select(.GroupName=="%s").GroupID' $GROUP_NAME
  groupId=$(./pcloud-cli.sh safe_groups_get $SAFE_NAME | jq -r "$query")

  accountId1=$(./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME1 | jq -r .id)
  ./pcloud-cli.sh safe_group_member_add $groupId $accountId1

  accountId2=$(./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME2 | jq -r .id)
  ./pcloud-cli.sh safe_group_member_add $groupId $accountId2
}

##################################################
get_group_info() {
  groupJson=$(./pcloud-cli.sh safe_groups_get $SAFE_NAME)
  echo "Groups in safe $SAFE_NAME:"
  echo $groupJson | jq .
  echo
  printf -v query '.[] | select(.GroupName=="%s").GroupID' $GROUP_NAME
  groupJson=$(./pcloud-cli.sh safe_groups_get $SAFE_NAME)
  groupId=$(echo $groupJson | jq -r "$query")
  if [[ "$groupId" != "" ]]; then
    echo "Group members:"
    ./pcloud-cli.sh safe_group_members_get $groupId | jq .
  fi
}

main "$@"
