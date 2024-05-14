#!/bin/bash
set -eou pipefail

source $CONJUR_HOME/config/conjur.config
source ../jenkinsvars.sh

main() {
  if [ $# != 1 ]; then
    echo "Usage: $0 <jenkins-job-name>"
    exit -1
  fi
  cybr conjur logon-non-interactive
  wait_for_synchronizer

  export POLICY_NAME=$1
  export APP_IDENTITY=$POLICY_NAME
  gen_and_load_policy
}

##############################
wait_for_synchronizer() {
  while [[ "$(cybr conjur list -k group | grep $SAFE_NAME/delegation/consumers)" == "" ]]; do
    sleep 10
  done
}

##############################
gen_and_load_policy() {

  FILE_PREFIX=$(echo $POLICY_NAME | sed 's#/#-#g')

  cat ./templates/app-identity-policy.template.yml		\
    | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"			\
    | sed -e "s#{{ APP_IDENTITY }}#$APP_IDENTITY#g"		\
    | sed -e "s#{{ JWT_CLAIM1_NAME }}#$TOKEN_APP_PROPERTY#g"	\
    | sed -e "s#{{ JWT_CLAIM1_VALUE }}#$APP_IDENTITY#g"		\
    > ./policy/$FILE_PREFIX-identity-policy.yml

  cybr conjur update-policy -b apps -f ./policy/$FILE_PREFIX-identity-policy.yml

  cat ./templates/app-safe-policy.template.yml			\
    | sed -e "s#{{ LOB_NAME }}#$LOB_NAME#g"			\
    | sed -e "s#{{ SAFE_NAME }}#$SAFE_NAME#g"			\
    | sed -e "s#{{ APP_IDENTITY }}#$APP_IDENTITY#g"		\
    > ./policy/$FILE_PREFIX-safe-policy.yml

  cybr conjur update-policy -b $VAULT_NAME -f ./policy/$FILE_PREFIX-safe-policy.yml
}

main "$@"
