#!/bin/bash
if [[ -z $1 ]] ; then
	printf "\n\tUsage: %s <policy-file-name>\n\n" $0
	exit 1
fi
POLICY_FILE=$1
conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD
conjur policy load root $POLICY_FILE
