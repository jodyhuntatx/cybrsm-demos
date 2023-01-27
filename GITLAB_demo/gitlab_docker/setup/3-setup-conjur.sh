#!/bin/bash

# Doc for Conjur GitLab integration:
# https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/Operations/Services/cjr-authn-jwt-uc.htm

CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos} 

source $CONJUR_HOME/config/conjur.config
source ../gitlabvars.sh

main() {
  cybr conjur logon-non-interactive
  initialize_authn_jwt
  grant_authn_permission_to_apps_authenticators_group
}

########################
initialize_authn_jwt() {
  echo "Initializing Conjur JWT authentication policy for GitLab..."

  cybr conjur update-policy -b root -f ./policy/authn-jwt-gitlab.yml

#  $CONJUR_HOME/bin/enable_all_configured_authenticators.sh

  pub_keys=$(curl -k $JWKS_URI)
  cybr conjur set-secret 					\
	-i conjur/authn-jwt/$SERVICE_ID/public-keys		\
        -v "{\"type\":\"jwks\", \"value\":$pub_keys}"
  cybr conjur set-secret					\
	-i conjur/authn-jwt/$SERVICE_ID/issuer			\
	-v $JWT_ISSUER
  cybr conjur set-secret					\
	-i conjur/authn-jwt/$SERVICE_ID/token-app-property	\
	-v $TOKEN_APP_PROPERTY
  cybr conjur set-secret					\
	-i conjur/authn-jwt/$SERVICE_ID/identity-path		\
	-v $IDENTITY_PATH
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
