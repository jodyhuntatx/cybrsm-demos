#!/bin/bash

REGIONS=(
us-east-1
us-east-2
ca-central-1
us-west-1
us-west-2
)

showUsage() {
  echo "Usage:"
  echo "  $0 m[anaged]"
  echo "  $0 u[nmanaged]"
  echo "  $0 d[escribe unmanaged]"
  exit -1
}


case $1 in
  m*)
	for region in "${REGIONS[@]}"; do
	  rm -f $region-managed-awssmgr.json
	  MANAGED_SECRETS=$(./aws-smgr-cli.sh secrets_managed_get $region)
	  echo $MANAGED_SECRETS >> $region-managed-awssmgr.json
	done
	;;

  u*)
	for region in "${REGIONS[@]}"; do
	  rm -f $region-unmanaged-awssmgr.json
	  UNMANAGED_SECRETS=$(./aws-smgr-cli.sh secrets_unmanaged_get $region)
	  echo $UNMANAGED_SECRETS >> $region-unmanaged-awssmgr.json
	done
	;;

  d*)
	rm -f unmanaged-descriptions.json
	for region in "${REGIONS[@]}"; do
	  for name in "$(cat $region-unmanaged-awssmgr.json | jq -r .Name)"; do
	    ./aws-smgr-cli.sh secret_describe $region $name >> unmanaged-descriptions.json
	  done
	done
	;;

  *)	echo "Unrecognized command."
	showUsage
	;;
esac
