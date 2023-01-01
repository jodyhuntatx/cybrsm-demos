#!/bin/bash
set -eou pipefail

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source $CONJUR_HOME/config/dockerdesktop.k8s

main() {
  get_configured_authns
  gen_and_apply_config_file
  wait_till_node_is_responsive
  echo_enabled_authns
}

############################
get_configured_authns() {
  configured_authns=$(curl -sk $CONJUR_APPLIANCE_URL/info | jq -r .authenticators.configured[])
  echo "Configured Authenticators:"
  echo "    "$configured_authns
  echo
}

############################
gen_and_apply_config_file() {
  echo "# List of authenticators enabled for this cluster" > ./tmp.out
  echo "authenticators:" >> ./tmp.out
  for i in $configured_authns; do
    echo "  - $i" >> ./tmp.out
  done
  echo "_:" >> ./tmp.out
  $DOCKER cp ./tmp.out $CONJUR_LEADER_CONTAINER_NAME:/etc/conjur/config/conjur.yml
  rm ./tmp.out
  $DOCKER exec $CONJUR_LEADER_CONTAINER_NAME                            \
      evoke configuration apply
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
echo_enabled_authns() {
  echo "Enabled Authenticators:"
  enabled_authns=$(curl -sk $CONJUR_APPLIANCE_URL/info | jq -r .authenticators.enabled[])
  echo "    "$enabled_authns
}

main "$@"
