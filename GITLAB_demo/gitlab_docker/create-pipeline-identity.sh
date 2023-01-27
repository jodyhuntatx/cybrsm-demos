#!/bin/bash
set -eou pipefail

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source ./gitlabvars.sh

main() {
  if [ $# != 1 ]; then
    echo
    echo "Usage: $0 <gitlab-instance-id-slash-project-name>"
    echo
    echo "Example:"
    echo "    $0 gitlab-instance-b33283e7/conjur-demo"
    echo
    exit -1
  fi
  CONJUR_IDENTITY=$1
  cybr conjur logon-non-interactive
  wait_for_synchronizer

  export POLICY_NAME=$CONJUR_IDENTITY
  pushd ./setup
    gen_and_load_policy
  popd
}

##############################
wait_for_synchronizer() {
  echo "Waiting for synchronizer to sync $SAFE_NAME to Conjur..."
  while [[ "$(cybr conjur list -k group | grep $SAFE_NAME/delegation/consumers)" == "" ]]; do
    sleep 10
    echo -n "."
  done
}

##############################
gen_and_load_policy() {

  FILE_PREFIX=$(echo $POLICY_NAME | sed 's#/#-#g')

  cat ./templates/app-identity-policy.template.yml		\
    | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"			\
    | sed -e "s#{{ CONJUR_IDENTITY }}#$CONJUR_IDENTITY#g"	\
    | sed -e "s#{{ JWT_CLAIM1_NAME }}#$TOKEN_APP_PROPERTY#g"	\
    | sed -e "s#{{ JWT_CLAIM1_VALUE }}#$CONJUR_IDENTITY#g"	\
    > ./policy/$FILE_PREFIX-identity-policy.yml

  cybr conjur update-policy -b apps -f ./policy/$FILE_PREFIX-identity-policy.yml

  cat ./templates/app-safe-policy.template.yml			\
    | sed -e "s#{{ LOB_NAME }}#$LOB_NAME#g"			\
    | sed -e "s#{{ SAFE_NAME }}#$SAFE_NAME#g"			\
    | sed -e "s#{{ CONJUR_IDENTITY }}#$CONJUR_IDENTITY#g"	\
    > ./policy/$FILE_PREFIX-safe-policy.yml

  cybr conjur update-policy -b $VAULT_NAME -f ./policy/$FILE_PREFIX-safe-policy.yml
}

main "$@"
