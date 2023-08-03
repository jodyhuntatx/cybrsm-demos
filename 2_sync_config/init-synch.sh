#!/bin/bash

if [[ $# != 1 ]]; then
  echo "Usage: $0 [ mac | aws | azure ]"
  exit -1
fi

case $1 in
  mac)
	export MASTER_PLATFORM=dockerdesktop
	export SYNC_HOST=Sync_WIN-6COKN51MA8P
	export VAULT_NAME=DemoVault
	;;
  aws)
	export MASTER_PLATFORM=aws
	export SYNC_HOST=Sync_WIN-5A98H2P8FNR
	export VAULT_NAME=DemoVault
	;;
  azure)
	export MASTER_PLATFORM=azure
	export SYNC_HOST=Sync_WIN-206D32OIKB7
	export VAULT_NAME=DemoVault
	;;
  pcloud-aws)
	export MASTER_PLATFORM=aws
	export SYNC_HOST=Sync_EC2AMAZ-UIFMB6D
	export VAULT_NAME=jodypc
	;;
  pcloud-azure)
	export MASTER_PLATFORM=azure
	export SYNC_HOST=Sync_EC2AMAZ-UIFMB6D
	export VAULT_NAME=jodypc
	;;
  *)
	echo "Master platform $1 not supported."
	exit -1
	;;
esac

source ../config/conjur.config
source ../bin/conjur_utils.sh

export CONJUR_AUTHN_LOGIN=$CONJUR_ADMIN_USERNAME
export CONJUR_AUTHN_API_KEY=$CONJUR_ADMIN_PASSWORD

cat ./vault-sync-policy.template		\
  | sed -e "s#{{ VAULT_NAME }}#$VAULT_NAME#g"	\
  | sed -e "s#{{ SYNC_HOST }}#$SYNC_HOST#g"	\
  > vault-sync-policy.yml

if $FIRST_TIME; then
  conjur_append_policy root vault-sync-policy.yml
else
  conjur_update_policy root vault-sync-policy.yml
fi
NEW_API_KEY=$(conjur_rotate_api_key host $SYNC_HOST)
echo
echo "Synchronizer authn creds for Conjur primary on $MASTER_PLATFORM:"
echo "  Hostname: host/$SYNC_HOST"
echo "  API key: $NEW_API_KEY"
echo "  Conjur URL: $CONJUR_APPLIANCE_URL"
echo "  Conjur Account: $CONJUR_ACCOUNT"
echo

#rm ./vault-sync-policy.yml
