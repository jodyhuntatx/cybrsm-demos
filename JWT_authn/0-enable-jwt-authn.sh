#!/bin/bash
set -eou pipefail

source ../config/conjur.config
source ../bin/conjur_utils.sh

export JWT_POLICY_TEMPLATE=authn-jwt.yml.template
export SERVICE_ID=jenkins
export JWKS_URI=http://conjur-master-mac:8086/jwtauth/conjur-jwk-set

export PROJECT_NAME=jenkins
export APP_IDENTITY=PluginDemo-Pipeline

export TOKEN_APP_PROPERTY=jenkins_name	# claim containing name of host identity
export IDENTITY_PATH=$PROJECT_NAME	# Conjur policy path to host identity definition

export JWT_ISSUER=http://conjur-master-mac:8086
# Note: all Conjur hosts must include annotations for enforced claims
export ENFORCED_CLAIMS=jenkins_task_noun,jenkins_pronoun

# This script enables authn-jwt in a running Conjur node (Master or Follower) running in Docker.
# It's useful for enabling authn-jwt after standing the node up.
# It must be run on the host where the Conjur node is running.

#################
main() {
  configure_authn_jwt
  wait_till_node_is_responsive
  curl -k $CONJUR_LEADER_URL/info
  set_authn_jwt_variables
}

###################################
configure_authn_jwt() {
  echo "Initializing Conjur JWT authentication policy..."

  cat ./templates/$JWT_POLICY_TEMPLATE				\
  | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"		\
  > ./policy/$JWT_POLICY_TEMPLATE
  conjur_append_policy root ./policy/$JWT_POLICY_TEMPLATE delete

  $DOCKER exec $CONJUR_LEADER_CONTAINER_NAME				\
        evoke variable set CONJUR_AUTHENTICATORS authn-jwt/$SERVICE_ID

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
set_authn_jwt_variables() {
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/issuer $JWT_ISSUER
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/jwks-uri  $JWKS_URI
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/enforced-claims $ENFORCED_CLAIMS
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/token-app-property $TOKEN_APP_PROPERTY
  conjur_set_variable conjur/authn-jwt/$SERVICE_ID/identity-path $IDENTITY_PATH
}

main "$@"
