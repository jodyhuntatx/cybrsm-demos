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

  $CLI get clusterrole > before.txt
  $CLI get clusterrolebindings >> before.txt
  $CLI get roles --all-namespaces >> before.txt
  $CLI get rolebindings --all-namespaces >> before.txt

  cat ./templates/follower-authn-cm.template.yaml		\
  > ./manifests/follower-authn-cm.yaml

  cat ./templates/follower-deployment.template.yaml		\
  > ./manifests/follower-deployment.yaml
  $CLI apply -f ./manifests/follower-deployment.yaml

  $CLI get clusterrole > after.txt
  $CLI get clusterrolebindings >> after.txt
  $CLI get roles --all-namespaces >> after.txt
  $CLI get rolebindings --all-namespaces >> after.txt
  echo
  echo "		RBAC before						RBAC after"
  sdiff -s before.txt after.txt
  echo
}

main "$@"
