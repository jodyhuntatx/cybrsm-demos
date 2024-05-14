#!/bin/bash
if [[ -z "${CONJUR_HOME}" ]]; then
  echo "Set CONJUR_HOME to demo base directory."; exit -1
fi
source $CONJUR_HOME/config/conjur.config

K8SOP_VERSION=2.1.5
SHA=c1d57e0
BASE_DIR=~/conjur-install-images/conjur-kubernetes-operator-$K8SOP_VERSION-$SHA

main() {
  cp $BASE_DIR/operator/manifests/*.yaml .
  cp $BASE_DIR/samples/* .
  pushd $BASE_DIR
    load_operator_img
    load_follower_img configurator
    load_follower_img conjur
    load_follower_img info
    load_follower_img nginx
    load_follower_img postgres
    load_follower_img syslog-ng
  popd
}

########################
load_operator_img() {
  $DOCKER load -i operator/images/conjur-kubernetes-follower-operator-$K8SOP_VERSION-$SHA.tar
}

########################
load_follower_img() {
  if [[ $# != 1 ]]; then
    echo "Provide image name qualifier as argument."; exit -1
  fi
  $DOCKER load -i follower/images/conjur-kubernetes-follower-$1-$K8SOP_VERSION-$SHA.tar
}

main "$@"
