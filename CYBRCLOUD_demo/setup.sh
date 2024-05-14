#!/bin/bash

source ./demovars.sh

main() {
  conjur login -i $CONJUR_ADMIN_USER -p $CONJUR_ADMIN_PWD
  setupAuthnJwt
  createWorkloadIdentity
  grantWorkloadAuthn
  grantWorkloadAccess
}

############################
setupAuthnJwt() {
  cat policy/authn-jwt.yml			\
  | sed "s#{{ SERVICE_ID }}#$SERVICE_ID#"	\
  > tmp 
  conjur policy load -b conjur/authn-jwt -f tmp
  pub_keys=$(echo {\"type\":\"jwks\", \"value\": "$PUB_KEYS"})
  conjur variable set -i conjur/authn-jwt/$SERVICE_ID/public-keys -v "$pub_keys"
  conjur variable set -i conjur/authn-jwt/$SERVICE_ID/issuer -v $ISSUER
  conjur variable set -i conjur/authn-jwt/$SERVICE_ID/token-app-property -v $APP_PROPERTY
  conjur variable set -i conjur/authn-jwt/$SERVICE_ID/identity-path -v $ID_PATH
  conjur variable set -i conjur/authn-jwt/$SERVICE_ID/audience -v $AUDIENCE
  conjur authenticator enable -i authn-jwt/$SERVICE_ID
}

############################
createWorkloadIdentity() {
  cat policy/workload-identity.yml		\
  | sed "s#{{ WORKLOAD_ID }}#$FLOWS_WORKLOAD_ID#"	\
  | sed "s#{{ SERVICE_ID }}#$SERVICE_ID#"	\
  | sed "s#{{ APP_PROPERTY }}#$APP_PROPERTY#"	\
  > tmp
  conjur policy update -b $ID_PATH -f tmp
  rm tmp
}

############################
grantWorkloadAccess() {
  cat policy/workload-access-grant.yml		\
  | sed "s#{{ WORKLOAD_ID }}#$FLOWS_WORKLOAD_ID#"	\
  | sed "s#{{ SERVICE_ID }}#$SERVICE_ID#"	\
  > tmp
  conjur policy update -b $ID_PATH -f tmp
  rm tmp
}

############################
grantWorkloadAuthn() {
  cat policy/workload-authn-grant.yml		\
  | sed "s#{{ WORKLOAD_ID }}#$FLOWS_WORKLOAD_ID#"	\
  | sed "s#{{ SERVICE_ID }}#$SERVICE_ID#"	\
  | sed "s#{{ ID_PATH }}#$ID_PATH#"	\
  > tmp
  conjur policy update -b conjur/authn-jwt -f tmp
  rm tmp
}

main "$@"
