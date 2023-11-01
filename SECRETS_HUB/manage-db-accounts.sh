#!/bin/bash

case $1 in
  p*)	command="provision"
	;;
  d*)	command="deprovision"
	;;
  *)	echo "arg must be p or d."
	exit -1
	;;
esac

source ./demo-vars.sh

export CLOUD_PLATFORM_IDS="AWSAccessKeys"
export SSH_PLATFORM_IDS="UnixSSHKeys InformixUnixSSH DB2UnixSSH"
export DB_PLATFORM_IDS="MySQL MSSql Oracle SAPHANA Sybase"

CYBRVAULT_CLI=../bin/cybrvault-cli.sh

declare -a ALL_PLATFORM_IDS=(
AWSAccessKeys
UnixSSHKeys
InformixUnixSSH
DB2UnixSSH
MySQL
MSSql
Oracle
SAPHANA
Sybase)

export SAFE_NAME=PendingAccounts
export SERVER_ADDRESS=192.168.0.254
export SERVER_PORT=3306
export DATABASE_NAME=testdb
export USERNAME=root
export PASSWORD=Cyberark1
export SSH_KEY="$(cat ~/.ssh/id_oshift)"

export AWS_SECRET_KEY="ME98kJQKXpFnaVdpJroLi5ebe6w+Gv3H2dEk"
export AWS_REGION="us-east-1"
export AWS_ACCESS_KEY="ASIAW5PALCL6UZJT"
export AWS_ACCOUNT_ID="1234567"
export AWS_ACCOUNT_ALIAS="Onboarding testing"

case $command in
  provision)
    # provision AWS Access Keys account
    platformId=AWSAccessKeys
    ACCOUNT_NAME=${platformId}-Onboarded
    $CYBRVAULT_CLI/account_create_aws 		\
			"$SAFE_NAME"		\
			"$platformId"		\
			"$ACCOUNT_NAME"		\
			"$USERNAME"		\
			"$AWS_SECRET_KEY"	\
			"$AWS_REGION"		\
			"$AWS_ACCESS_KEY"	\
			"$AWS_ACCOUNT_ID"	\
			"$AWS_ACCOUNT_ALIAS"

    # provision SSH account
    platformId=UnixSSHKeys
    ACCOUNT_NAME=${platformId}-Onboarded
    $CYBRVAULT_CLI account_create_ssh 		\
			"$SAFE_NAME"		\
			"$platformId"		\
			"$ACCOUNT_NAME"		\
			"$SERVER_ADDRESS"	\
			"$USERNAME"		\
			"$SSH_KEY"

    # provision Informix via SSH account
    platformId=InformixUnixSSH
    ACCOUNT_NAME=${platformId}-Onboarded
    $CYBRVAULT_CLI account_create_ssh          \
                        "$SAFE_NAME"            \
                        "$platformId"           \
                        "$ACCOUNT_NAME"         \
                        "$SERVER_ADDRESS"       \
                        "$USERNAME"             \
                        "$SSH_KEY"

    # provision DB2 via SSH account
    platformId=DB2UnixSSH
    ACCOUNT_NAME=${platformId}-Onboarded
    $CYBRVAULT_CLI account_create_ssh          \
                        "$SAFE_NAME"            \
                        "$platformId"           \
                        "$ACCOUNT_NAME"         \
                        "$SERVER_ADDRESS"       \
                        "$USERNAME"             \
                        "$SSH_KEY"

    # provision DB accounts
    for platformId in $DB_PLATFORM_IDS; do
      accountName=${platformId}-Onboarded
      $CYBRVAULT_CLI account_create_db \
			$SAFE_NAME	\
			$platformId	\
			$accountName	\
			$SERVER_ADDRESS	\
			$USERNAME	\
			$PASSWORD	\
			$DATABASE_NAME	\
			$SERVER_PORT

    done
    ;;

  deprovision)
    for platformId in "${ALL_PLATFORM_IDS[@]}"; do
      accountName=${platformId}-Onboarded
      $CYBRVAULT_CLI account_delete $SAFE_NAME "$accountName"
#     $CYBRVAULT_CLI account_get $SAFE_NAME "$accountName"
    done
    ;;

  *)
    echo "Unknown command: $command"
    exit -1
    ;;
esac
