#!/bin/bash
set -eou pipefail

source ../../config/conjur.config
source ../../bin/conjur_utils.sh
source ../jenkins-demo.config

# This script enables authn-jwt in a running Conjur node (Master or Follower) running in Docker.
# It's useful for enabling authn-jwt after standing the node up.
# It must be run on the host where the Conjur node is running.

echo "Initializing Conjur JWT authentication policy..."

cat ./templates/$JWT_POLICY_TEMPLATE			\
  | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"		\
  > ./policy/$PROJECT_NAME-authn-jwt.yml
conjur_append_policy root ./policy/$PROJECT_NAME-authn-jwt.yml delete

$CONJUR_HOME/bin/enable_all_configured_authenticators.sh

conjur_set_variable conjur/authn-jwt/$SERVICE_ID/issuer $JWT_ISSUER
conjur_set_variable conjur/authn-jwt/$SERVICE_ID/jwks-uri  $JWKS_URI
conjur_set_variable conjur/authn-jwt/$SERVICE_ID/token-app-property $TOKEN_APP_PROPERTY
conjur_set_variable conjur/authn-jwt/$SERVICE_ID/identity-path $IDENTITY_PATH
#conjur_set_variable conjur/authn-jwt/$SERVICE_ID/enforced-claims $ENFORCED_CLAIMS
