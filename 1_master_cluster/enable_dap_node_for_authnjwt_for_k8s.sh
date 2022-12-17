#!/bin/bash
set -eou pipefail

source ../config/conjur.config
source ../config/$MASTER_PLATFORM.k8s
source ../bin/conjur_utils.sh

# This script enables authn-jwt for a K8s namespace
# in a running Conjur node (Master or Follower) running in Docker.
# It's useful for enabling authn-jwt after standing the node up.
# It must be run on the host where the Conjur node is running.
# It does NOT need to use kubectl or oc.

#################
main() {
  configure_authn_jwt
  wait_till_node_is_responsive
  curl -k $CONJUR_LEADER_URL/info
  update_follower_cert
}

###################################
configure_authn_jwt() {

  echo "Loading Conjur JWT authentication policy..."

  cat ./templates/authn-jwt-policy.template.yaml		\
  | sed -e "s#{{ APP_NAMESPACE_NAME }}#$APP_NAMESPACE_NAME#g"	\
  > ./policy/authn-jwt-$APP_NAMESPACE_NAME-policy.yaml

  conjur_append_policy root ./policy/authn-jwt-$APP_NAMESPACE_NAME-policy.yaml delete

  # authn-jwt pre-enabled via conjur.yml file in leader
}

############################
wait_till_node_is_responsive() {
  set +e
  node_is_healthy=""
  while [[ "$node_is_healthy" == "" ]]; do
    sleep 2
    node_is_healthy=$(curl -sk $CONJUR_LEADER_URL/health | grep "ok" | tail -1 | grep "true")
  done
  set -e
}

############################
update_follower_cert() {

  rm -f $FOLLOWER_CERT_FILE
  $DOCKER exec $CONJUR_LEADER_CONTAINER_NAME \
        bash -c "evoke ca issue -f conjur-follower $CONJUR_FOLLOWER_SERVICE_NAME"
  $DOCKER cp -L $CONJUR_LEADER_CONTAINER_NAME:/opt/conjur/etc/ssl/conjur-follower.pem $FOLLOWER_CERT_FILE
}

main "$@"
