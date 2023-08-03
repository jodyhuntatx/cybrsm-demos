#!/bin/bash

# Doc for Conjur Jenkins plugin:
# https://plugins.jenkins.io/conjur-credentials/

source $CONJUR_HOME/config/conjur.config
source ../jenkinsvars.sh

main() {
  cybr conjur logon-non-interactive
  initialize_authn_jwt
  grant_authn_permission_to_apps_authenticators_group
}

########################
initialize_authn_jwt() {
  echo "Initializing Conjur JWT authentication policy for Cloudbees Jenkins..."

  cybr conjur update-policy -b root -f ./policy/authn-jwt-jenkins.yml

  echo ">>>>>>>>>> Authenticator enabling disable <<<<<<<<<<"
  $CONJUR_HOME/bin/enable_all_configured_authenticators.sh

  cybr conjur set-secret -i conjur/authn-jwt/$SERVICE_ID/audience -v $JWT_AUDIENCE
  cybr conjur set-secret -i conjur/authn-jwt/$SERVICE_ID/issuer -v $JWT_ISSUER
  cybr conjur set-secret -i conjur/authn-jwt/$SERVICE_ID/jwks-uri -v $JWKS_URI
  cybr conjur set-secret -i conjur/authn-jwt/$SERVICE_ID/token-app-property -v $TOKEN_APP_PROPERTY
  cybr conjur set-secret -i conjur/authn-jwt/$SERVICE_ID/identity-path -v $IDENTITY_PATH
}

########################
grant_authn_permission_to_apps_authenticators_group() {
				# Give authenticators group authn permission to all authenticator endpoints
  authenticator_list=$(cybr conjur list -k webservice | grep authn | grep -v status | cut -d : -f 3 | cut -d \" -f 1)
  for i in $authenticator_list; do
    cat > ./tmp << END_POLICY
- !permit
  role: !group /apps/authenticators
  privileges: [ authenticate ]
  resource: !webservice $i
END_POLICY
    cybr conjur append-policy -b root -f ./tmp
  done
  rm ./tmp
}

main "$@"
