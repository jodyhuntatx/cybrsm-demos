#!/bin/bash
set -eu

source ../../config/conjur.config
source ../env/pkiaas.env
source ../env/sandbox.env
source ./env/mtls-demo.config
source ../bashlib/conjur_utils.sh

main() {
  export CONJUR_AUTHN_LOGIN="${CONJUR_PKI_ADMIN}"
  export CONJUR_AUTHN_API_KEY="${CONJUR_PKI_ADMIN_API_KEY}"
  conjur_access_token=$(conjur_authenticate)
  export conjur_access_token="$conjur_access_token"

  # Conjurize server so it can retrieve TLS creds dynamically
  MTLS_SERVER_API_KEY=$(conjur_rotate_api_key host $MTLS_SERVER_LOGIN)
  create_id_files server $MTLS_SERVER_LOGIN $MTLS_SERVER_API_KEY ./build/server/
  docker-compose build server
  rm ./build/server/conjur*

  # Conjurize client so it can retrieve TLS creds dynamically
  MTLS_CLIENT_API_KEY=$(conjur_rotate_api_key host $MTLS_CLIENT_LOGIN)
  create_id_files client $MTLS_CLIENT_LOGIN $MTLS_CLIENT_API_KEY ./build/client/
  docker-compose build client
  rm ./build/client/conjur*
}

create_id_files() {
# creates conjur* conjurization files in the target build directory 
  local CONT_ID=$1; shift
  local HOST_LOGIN=$1; shift
  local HOST_API_KEY=$1; shift
  local BUILD_DIR=$1; shift

  # Copy cert to build dir
  cp $LEADER_CERT_FILE $BUILD_DIR

  # Create identity files (AKA .netrc)
  echo "Generating $HOST_LOGIN identity file..."
  cat <<IDENTITY_EOF | tee $BUILD_DIR/conjur.identity
machine $CONJUR_APPLIANCE_URL/authn
  login host/$HOST_LOGIN
  password $HOST_API_KEY
IDENTITY_EOF

  # Create config file for Conjur service
  echo
  echo "Generating $HOST_LOGIN configuration file..."
  cat <<CONF_EOF | tee $BUILD_DIR/conjur.conf
---
appliance_url: $CONJUR_APPLIANCE_URL
account: $CONJUR_ACCOUNT
netrc_path: "/etc/conjur.identity"
cert_file: "/etc/$CONJUR_LEADER_HOSTNAME-$CONJUR_ACCOUNT.pem"
CONF_EOF
}

main "$@"
