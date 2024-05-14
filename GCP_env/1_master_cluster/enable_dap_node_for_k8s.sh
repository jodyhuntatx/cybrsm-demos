#!/bin/bash
set -eou pipefail

source ../config/conjur.config
source ../config/dockerdesktop.k8s

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
  configure_authn_k8s
  whitelist_configured_authenticators
  wait_till_node_is_responsive
  curl -k $DAP_NODE_URL/info
}

###################################
configure_authn_k8s() {
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

  if [[ $DAP_NODE_CONTAINER_NAME == $CONJUR_MASTER_CONTAINER_NAME ]]; then
    echo "Initializing CA in Conjur Master..."
    $DOCKER exec $DAP_NODE_CONTAINER_NAME \
      chpst -u conjur conjur-plugin-service possum \
        rake authn_k8s:ca_init["conjur/authn-k8s/$AUTHENTICATOR_ID"]
    echo "CA initialized."
  else
    echo "Note: CA must be initialized on Master."
  fi
}

############################
whitelist_configured_authenticators() {
  echo "Updating list of whitelisted authenticators..."
  $DOCKER exec $DAP_NODE_CONTAINER_NAME \
	evoke variable set CONJUR_AUTHENTICATORS $(curl -sk https://localhost/info | jq -r '.authenticators.configured | join(",")')

					# get current authenticators in conjur.conf
  $DOCKER exec $DAP_NODE_CONTAINER_NAME cat /opt/conjur/etc/conjur.conf > temp.conf
  set +e
  authn_str=$(grep AUTHENTICATORS temp.conf)
  set -e

  if [[ "$authn_str" == "" ]]; then	# If no authenticators specified...
					# add authenticators to conjur.conf
    echo "CONJUR_AUTHENTICATORS=\"${CONJUR_AUTHENTICATORS}\"" >> temp.conf
    $DOCKER exec -i $DAP_NODE_CONTAINER_NAME dd of=/opt/conjur/etc/conjur.conf < temp.conf
  else
					# else replace line in conjur.conf
    $DOCKER exec $DAP_NODE_CONTAINER_NAME \
		sed -i.bak "s#CONJUR_AUTHENTICATORS=.*#CONJUR_AUTHENTICATORS=\"${CONJUR_AUTHENTICATORS}\"#" \
		/opt/conjur/etc/conjur.conf
  fi
  rm -f temp.conf
  $DOCKER exec $DAP_NODE_CONTAINER_NAME sv restart conjur

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
