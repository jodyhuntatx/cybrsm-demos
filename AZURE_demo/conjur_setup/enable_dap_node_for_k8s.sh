#!/bin/bash
set -eou pipefail

source ./azure.config
AUTHENTICATOR_ID=aws-eks
CONJUR_NAMESPACE_NAME=cyberark
CONJUR_SERVICEACCOUNT_NAME=conjur-cluster
export PATH=$PATH:.

# This script enables authn-k8s in a running DAP node (Master or Follower) running in Docker.
# It's useful for enabling authn-k8s after standing the node up.
# It must be run on the host where the DAP node is running.
# It does NOT need to use kubectl or oc.

NEW_AUTHENTICATOR="authn-k8s/$AUTHENTICATOR_ID"

# For Master
DAP_NODE_CONTAINER_NAME=$CONJUR_MASTER_CONTAINER_NAME
DAP_NODE_URL=$CONJUR_APPLIANCE_URL
# For Follower
#DAP_NODE_CONTAINER_NAME=conjur-follower
#DAP_NODE_URL=https://$CONJUR_MASTER_HOST_NAME:$CONJUR_FOLLOWER_PORT

#################
main() {
  load_follower_authn_policies
  initialize_ca
  add_new_authenticator
  wait_till_node_is_responsive
  curl -k $DAP_NODE_URL/info
}

###################################
load_follower_authn_policies() {
  echo "Initializing Conjur authorization policies..."

  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" \
     ./policy/templates/cluster-authn-defs.template.yml |
    sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" |
    sed -e "s#{{ CONJUR_SERVICEACCOUNT_NAME }}#$CONJUR_SERVICEACCOUNT_NAME#g" \
    > ./policy/cluster-authn-defs.yml

  sed -e "s#{{ AUTHENTICATOR_ID }}#$AUTHENTICATOR_ID#g" \
    ./policy/templates/seed-service.template.yml |
    sed -e "s#{{ CONJUR_NAMESPACE_NAME }}#$CONJUR_NAMESPACE_NAME#g" |
    sed -e "s#{{ CONJUR_SERVICEACCOUNT_NAME }}#$CONJUR_SERVICEACCOUNT_NAME#g" \
    > ./policy/seed-service.yml

  POLICY_FILE_LIST="
  ./policy/cluster-authn-defs.yml
  ./policy/seed-service.yml
  "
  for i in $POLICY_FILE_LIST; do
        echo "Loading policy file: $i"
        load_policy_REST.sh root "$i"
  done

  echo "Conjur policies loaded."
}

############################
initialize_ca() {
  if [[ $DAP_NODE_CONTAINER_NAME == $CONJUR_MASTER_CONTAINER_NAME ]]; then
    echo "Initializing CA in Conjur Master..."
    sudo docker exec $DAP_NODE_CONTAINER_NAME \
      chpst -u conjur conjur-plugin-service possum \
        rake authn_k8s:ca_init["conjur/authn-k8s/$AUTHENTICATOR_ID"]
    echo "CA initialized."
  else
    echo "Note: CA must be initialized on Master."
  fi
}

############################
add_new_authenticator() {
  echo "Updating list of whitelisted authenticators..."
					# add authn-k8s endpoint if not already there
  current_authns=$(sudo docker exec conjur-master evoke variable list CONJUR_AUTHENTICATORS | cut -d = -f 2)
  if [[ "$current_authns" != *"authn-k8s/$AUTHENTICATOR_ID"* ]]; then
    sudo docker exec $DAP_NODE_CONTAINER_NAME evoke variable set CONJUR_AUTHENTICATORS $current_authns,authn-k8s/$AUTHENTICATOR_ID
  fi

  echo "Authenticators updated."
}

############################
wait_till_node_is_responsive() {
  set +e
  node_is_healthy=""
  while [[ "$node_is_healthy" == "" ]]; do
    sleep 2
    node_is_healthy=$(curl -sk $DAP_NODE_URL/health | grep "ok" | tail -1 | grep "true")
  done
  set -e
}

main "$@"
