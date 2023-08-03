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

export PLATFORM_IDS="MySQL MSSql Oracle SAPHANA Sybase"
#export PLATFORM_IDS="DB2UnixSSH InformixUnixSSH"
export SAFE_NAME=PendingAccounts
export SERVER_ADDRESS=192.168.0.254
export SERVER_PORT=3306
export DATABASE_NAME=testdb
export USERNAME=root
export PASSWORD=Cyberark1
export SSH_KEY="$(cat ~/.ssh/id_oshift)"

case $command in
  provision)
    # provision SSH account
    platformId=UnixSSHKeys
    ACCOUNT_NAME=${platformId}-Onboarded
    ./pcloud-cli.sh account_create_ssh 		\
			"$SAFE_NAME"		\
			"$platformId"		\
			"$ACCOUNT_NAME"		\
			"$SERVER_ADDRESS"	\
			"$USERNAME"		\
			"$SSH_KEY"
	exit

    # provision DB accounts
    for platformId in $PLATFORM_IDS; do
      ACCOUNT_NAME=${platformId}-Onboarded
      ./pcloud-cli.sh account_create_db \
			$SAFE_NAME	\
			$platformId	\
			$ACCOUNT_NAME	\
			$SERVER_ADDRESS	\
			$USERNAME	\
			$PASSWORD	\
			$DATABASE_NAME	\
			$SERVER_PORT

      ./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME
    done
    ;;

  deprovision)
    platformId=UnixSSHKeys
    ACCOUNT_NAME=${platformId}-Onboarded
    ./pcloud-cli.sh account_delete "$SAFE_NAME" "$ACCOUNT_NAME"

    exit

    for platformId in $PLATFORM_IDS; do
      ACCOUNT_NAME=${platformId}-Onboarded
      ./pcloud-cli.sh account_delete $SAFE_NAME $ACCOUNT_NAME
      ./pcloud-cli.sh account_get $SAFE_NAME $ACCOUNT_NAME
    done
    ;;

  *)
    echo "Unknown command: $command"
    exit -1
    ;;
esac
