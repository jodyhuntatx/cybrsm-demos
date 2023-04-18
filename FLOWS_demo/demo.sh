#!/bin/bash

#######################################
export ADMIN_USER=jody_bot@cyberark.cloud.3357
export ADMIN_PWD=$(keyring get cybrid jodybotpwd)
export FLOWS_DEV_TENANT=acj5413.flows.integration-cyberark.cloud
export FLOWS_PROD_TENANT=aao4987.flows.cyberark.cloud
#######################################

# Make sure you are using the correct tenant (Dev or Prod)
export FLOWS_TENANT=$FLOWS_DEV_TENANT

# Workload inputs
export FLOW_NAME="<set-in-case-stmt-below>"
export APP_ID=AnsibleId
export SAFE_NAME=rh_bot
export REQUESTOR=jody.hunt@cyberark.com
export SSH_ACCOUNT_NAME=Flows-SSH
export SSH_PKEY="$(cat ~/.ssh/jody-ca-central-1.pem | base64)"
export SSH_USER=ubuntu
export SSH_ADDRESS=192.168.99.100

if [[ $# != 1 ]]; then
  echo
  echo "Select 1 or 2)"
  echo "  1) Provision"
  echo "  2) Deprovision"
  echo
  read option
else
  option=$1
fi

case $option in
  1 | p | P) export FLOW_NAME=JodyTest-01-Provision
     ;;
  2 | d | D) export FLOW_NAME=JodyTest-03-Deprovision
     ;;
  *) echo "Invalid selection, exiting..."
     exit -1
     ;;
esac

echo
echo "Running:"
echo "  Tenant: $FLOWS_TENANT"
echo "  Flow: $FLOW_NAME"
echo "  AppID: $APP_ID"
echo "  SafeName: $SAFE_NAME"
echo "  RequestorEmail: $REQUESTOR"
echo "  SshAcctName: $SSH_ACCOUNT_NAME"
echo "  SshUser: $SSH_USER"
echo "  SshPkey: $SSH_PKEY"
echo "  SshAddress: $SSH_ADDRESS"
echo
set -x
curl -k -X POST						\
	-H 'Content-Type: application/json' 		\
	--data "{					\
		\"adminId\": \"$ADMIN_USER\",		\
		\"adminPassword\": \"$ADMIN_PWD\",	\
		\"appId\": \"$APP_ID\",			\
		\"safeName\": \"$SAFE_NAME\",		\
		\"requestorEmail\": \"$REQUESTOR\",	\
		\"sshAcctName\": \"$SSH_ACCOUNT_NAME\",	\
		\"sshUser\": \"$SSH_USER\",		\
		\"sshPkey\": \"$SSH_PKEY\",		\
		\"sshAddress\": \"$SSH_ADDRESS\"	\
	}"						\
	https://$FLOWS_TENANT/flows/$FLOW_NAME/play
echo
echo
