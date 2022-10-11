#!/bin/bash
set -eou pipefail

source $CONJUR_HOME/config/conjur.config
source ../jenkinsvars.sh

main() {
  cybr conjur logon-non-interactive
  wait_for_synchronizer

  export POLICY_NAME=mb-branch2-pipeline
  export APP_IDENTITY=$SAFE_NAME-$POLICY_NAME
  gen_and_load_policy
exit 

  source ./proj1-freestyle.config
  export POLICY_NAME=proj1-freestyle
  gen_and_load_policy

  source ./proj1-pipeline.config
  export POLICY_NAME=proj1-pipeline
  gen_and_load_policy

  source ./root-pipeline.config
  export POLICY_NAME=root-pipeline
  gen_and_load_policy

  source ./root-freestyle.config
  export POLICY_NAME=root-freestyle
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

  cat ./templates/app-identity-policy.template.yaml		\
    | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"			\
    | sed -e "s#{{ APP_IDENTITY }}#$APP_IDENTITY#g"		\
    | sed -e "s#{{ JWT_CLAIM1_NAME }}#$TOKEN_APP_PROPERTY#g"	\
    | sed -e "s#{{ JWT_CLAIM1_VALUE }}#$APP_IDENTITY#g"		\
    > ./policy/$POLICY_NAME-identity-policy.yaml

  cybr conjur update-policy -b apps -f ./policy/$POLICY_NAME-identity-policy.yaml

  cat ./templates/app-safe-policy.template.yaml			\
    | sed -e "s#{{ LOB_NAME }}#$LOB_NAME#g"			\
    | sed -e "s#{{ SAFE_NAME }}#$SAFE_NAME#g"			\
    | sed -e "s#{{ APP_IDENTITY }}#$APP_IDENTITY#g"		\
    > ./policy/$POLICY_NAME-safe-policy.yaml

  cybr conjur update-policy -b $VAULT_NAME -f ./policy/$POLICY_NAME-safe-policy.yaml
}

main "$@"
