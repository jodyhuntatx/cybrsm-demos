#!/bin/bash
set -ou pipefail

source ./gcp.config

export PROJECT_NAME=gcp-demo
export CONJUR_HOST_ID=gcp-client
export FQ_CONJUR_HOST_ID=$PROJECT_NAME/$CONJUR_HOST_ID

cat policy/templates/gcp-app-grant.template.yml				\
  | sed -e "s#{{ PROJECT_NAME }}#$PROJECT_NAME#g"                	\
  > policy/$PROJECT_NAME-grant.yml

cat policy/$PROJECT_NAME-grant.yml		\
  | $DOCKER exec -i conjur-cli conjur policy load root -
