#!/bin/bash  -x
. ./bootstrap.env
CONJUR_CERT_FILE=/var/jenkins_home/conjur-dev.pem
CONJUR_AUTHN_LOGIN=2_ExternalSummonDemo
HF_TOKEN_FILE=jobs_hf_token.txt

if [ $# -ne 1 ]; then
	printf "Specify an environment: dev, test or prod\n\n"
	exit -1
fi

ENV=$1
if [[ $ENV == prod ]]; then
	if [[ ! -f $HF_TOKEN_FILE ]]; then
		printf "Host factory token file for jobs does not exist.\n\n"
		exit -1
	fi


	read HF_TOKEN < $HF_TOKEN_FILE
	HF_NAME=jenkins/jobs_factory
	CONJUR_AUTHN_API_KEY=$(conjur hostfactory hosts create $HF_TOKEN $CONJUR_AUTHN_LOGIN | jq -r .api_key)
fi

summon -e $ENV bash -c "echo \$DB_UNAME \$DB_PWD"

