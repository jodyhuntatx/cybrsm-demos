#!/bin/bash 
set -eo pipefail

# if existing HF_TOKEN passed as argument
HF_TOKEN=""
if [[ $# == 1 ]]; then
	HF_TOKEN=$1
fi

POLICY_FILE=policy.yml
HF_NAME=jenkins/executor_factory
HF_MINUTES=720
HOST_AUTHN_NAME=Executor-master-0
VAR_NAME=secrets/db_username

conjur authn login -u admin -p $(sudo summon -p keyring.py --yaml 'xx: !var app/at' bash -c "echo \$xx")
conjur policy load --as-group=security_admin policy.yml
if [["$HF_TOKEN" == "" ]]; then
	HF_TOKEN=$(conjur hostfactory tokens create --duration-minutes $HF_MINUTES $HF_NAME | jq -r .[].token)
	conjur variable values add $VAR_NAME $(openssl rand -hex 12)
fi
conjur authn logout

echo "HF_TOKEN is" $HF_TOKEN
API_KEY=$(conjur hostfactory hosts create $HF_TOKEN $HOST_AUTHN_NAME | jq -r .api_key)
echo "API_KEY is" $API_KEY
conjur authn login -u host/$HOST_AUTHN_NAME -p $API_KEY
echo "Roles that can execute" $VAR_NAME
conjur resource permitted_roles variable:$VAR_NAME read
echo "Variable value:" $(conjur variable value $VAR_NAME)

