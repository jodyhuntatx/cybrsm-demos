#!/bin/bash

source ./gitlabvars.sh

main() {
  setupAuthnJwt
  createWorkloadIdentity
  grantWorkloadAuthn
  grantWorkloadAccess
}

############################
setupAuthnJwt() {
  cat policy/authn-jwt-$SERVICE_ID.yml		\
  | sed "s#{{ SERVICE_ID }}#$SERVICE_ID#"	\
  > tmp
  $BIN_DIR/ccloud-cli.sh append conjur/authn-jwt tmp
  PUB_KEYS="$(curl -sk $JWKS_URI)"
  pub_keys="$(echo {\"type\":\"jwks\", \"value\": "$PUB_KEYS"})"
  $BIN_DIR/ccloud-cli.sh set conjur/authn-jwt/$SERVICE_ID/public-keys "$pub_keys"
  $BIN_DIR/ccloud-cli.sh set conjur/authn-jwt/$SERVICE_ID/issuer $JWT_ISSUER
  $BIN_DIR/ccloud-cli.sh set conjur/authn-jwt/$SERVICE_ID/token-app-property $TOKEN_APP_PROPERTY
  $BIN_DIR/ccloud-cli.sh set conjur/authn-jwt/$SERVICE_ID/identity-path $IDENTITY_PATH
  $BIN_DIR/ccloud-cli.sh enable authn-jwt $SERVICE_ID
  $BIN_DIR/ccloud-cli.sh status authn-jwt $SERVICE_ID
}

############################
createWorkloadIdentity() {
  cat ./templates/workload-identity-policy.template.yml		\
  | sed "s#{{ WORKLOAD_ID }}#$WORKLOAD_ID#"			\
  | sed "s#{{ SERVICE_ID }}#$SERVICE_ID#"			\
  | sed "s#{{ TOKEN_APP_PROPERTY }}#$TOKEN_APP_PROPERTY#"	\
  > ./policy/workload-identity.yml
  $BIN_DIR/ccloud-cli.sh update $IDENTITY_PATH ./policy/workload-identity.yml
}

############################
grantWorkloadAccess() {
  cat templates/workload-safe-policy.template.yml	\
  | sed "s#{{ WORKLOAD_ID }}#$WORKLOAD_ID#"		\
  | sed "s#{{ VAULT_NAME }}#$VAULT_NAME#"		\
  | sed "s#{{ SAFE_NAME }}#$SAFE_NAME#"			\
  > ./policy/workload-access.yml
  $BIN_DIR/ccloud-cli.sh update $IDENTITY_PATH ./policy/workload-access.yml
}

############################
grantWorkloadAuthn() {
  cat templates/workload-authn-policy.template.yml	\
  | sed "s#{{ WORKLOAD_ID }}#$WORKLOAD_ID#"		\
  | sed "s#{{ SERVICE_ID }}#$SERVICE_ID#"		\
  | sed "s#{{ ID_PATH }}#$IDENTITY_PATH#"		\
  > ./policy/workload-authn.yml
  $BIN_DIR/ccloud-cli.sh update conjur/authn-jwt ./policy/workload-authn.yml
}

main "$@"
