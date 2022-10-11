#!/bin/bash

. ./bootstrap.env

if [ $# -ne 2 ]; then
	printf "Usage: $0 <env> <job-name>\n\n"
	exit -1
fi

ENV=$1
JENKINS_JOB_NAME=$2
conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD >& /dev/null
export CONJUR_HOST_NAME=jenkins/$JENKINS_JOB_NAME
export CONJUR_AUTHN_API_KEY=$(conjur host rotate_api_key -h $CONJUR_HOST_NAME)
conjur authn logout >& /dev/null
export CONJUR_AUTHN_LOGIN=host/$CONJUR_HOST_NAME
set -x
summon -e $ENV bash -c "curl -s -X POST -u admin:Cyberark1 http://localhost:8080/job/$JENKINS_JOB_NAME/buildWithParameters?token=xyz\&DB_UNAME=\$DB_UNAME\&DB_PWD=\$DB_PWD"
set +x
conjur authn login -u admin -p $CONJUR_ADMIN_PASSWORD >& /dev/null
