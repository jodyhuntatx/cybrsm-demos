
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

  cat ./templates/crds.template.yaml		\
  > ./manifests/crds.yaml
  $CLI apply -f ./manifests/crds.yaml

  cat ./templates/operator.template.yaml	\
  > ./manifests/operator.yaml
  $CLI apply -f ./manifests/operator.yaml
}

main "$@"
