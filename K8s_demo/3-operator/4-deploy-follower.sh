#!/bin/bash

if [[ -z "${CONJUR_HOME}" ]]; then
  echo "Set CONJUR_HOME to demo base directory."; exit -1
fi
source $CONJUR_HOME/config/conjur.config
source $CONJUR_HOME/bin/conjur_utils.sh

main() {
  if [[ "$PLATFORM" == "openshift" ]]; then
    $CLI login -u $CYBERARK_NAMESPACE_ADMIN
  fi
  mkdir -p ./manifests

  cat ./templates/follower-authn-cm.template.yaml		\
  > ./manifests/follower-authn-cm.yaml

  cat ./templates/follower-deployment.template.yaml		\
  > ./manifests/follower-deployment.yaml
  $CLI apply -f ./manifests/follower-deployment.yaml
}

main "$@"
