#!/bin/bash

export ADMIN_USER=jody_bot@cyberark.cloud.3357
export ADMIN_PWD=$(keyring get cybrid jodybotpwd)

export FLOWS_DEV_TENANT=acj5413.flows.integration-cyberark.cloud
export FLOWS_SE_TENANT=aao4987.flows.cyberark.cloud

export FLOWS_TENANT=$FLOWS_DEV_TENANT
export FLOW_NAME=JodyTest-01-Provision
export APP_ID=AnsibleId
export SAFE_NAME=rh_bot

echo
echo "Running:"
echo "  Tenant: $FLOWS_TENANT"
echo "  Flow: $FLOW_NAME"
echo "  AppID: $APP_ID"
echo "  SafeName: $SAFE_NAME"
echo
curl -k -X POST						\
	-H 'Content-Type: application/json' 		\
	--data "{					\
		\"adminId\": \"$ADMIN_USER\",		\
		\"adminSecret\": \"$ADMIN_PWD\",	\
		\"appId\": \"$APP_ID\",			\
		\"safeName\": \"$SAFE_NAME\"		\
	}"						\
	https://$FLOWS_TENANT/flows/$FLOW_NAME/play
echo
echo
