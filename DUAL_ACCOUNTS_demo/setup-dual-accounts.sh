#!/bin/bash

source ./demo-vars.sh

SAFE_NAME=TestDualAccounts
PLATFORM_ID=Test-MySQL-DualAccts
ACCOUNT_NAME1=Test-MySQL-DualAccts1
ACCOUNT_NAME2=Test-MySQL-DualAccts2

GROUP_NAME=Test-MySQL-AcctGroup

GROUP_PLATFORM_ID=MySQL-RotationGroup


#./pcloud-cli.sh safe_create $SAFE_NAME "Safe for testing dual accounts"
./pcloud-cli.sh account_create_db_dual $SAFE_NAME $PLATFORM_ID $ACCOUNT_NAME1 user1 user1Password 192.168.99.100 testdb 3306 MySQL-DA 1 Active
./pcloud-cli.sh account_create_db_dual $SAFE_NAME $PLATFORM_ID $ACCOUNT_NAME2 user1 user1Password 192.168.99.100 testdb 3306 MySQL-DA 2 Inactive
#./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME2

exit

./pcloud-cli.sh safe_group_create $SAFE_NAME $GROUP_NAME $GROUP_PLATFORM_ID

echo "Rotational Groups:"
./pcloud-cli.sh platform_rotational_groups_get
echo "Groups:"
./pcloud-cli.sh platform_groups_get
set -x
