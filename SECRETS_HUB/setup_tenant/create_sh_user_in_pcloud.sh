#!/bin/bash

source env-vars.sh

CYBRVAULT_CLI=~/Conjur/cybrsm-demos/bin/cybrvault-cli.sh

SECRETS_HUB_PASSWORD=Cyberark1

# This script assumes CYBERARK_ADMIN_USER is an Oauth2 confidential 
# client service user with Secrets Hub Admin role.
#
# To use an interactive Admin identity, you need to get 
# the Secrets Hub ID token in Chrome:
#  - Login to the tenant as a user with Secrets Hub Admin role.
#  - Press F12 (Developer Tools) click the 'Application' tab. 
#  - Under 'Storage->Cookies', choose the Secrets Hub URL cookie.
#  - Click on 'Value' for the cookied named 'idToken-xxxxxx'.
#  - Copy/paste that value in quotes below.
#  - Comment out the call to get the auth token in createSourceSecretStore
SECRETS_HUB_ID_TOKEN=""

CURL="curl -sk"

main() {
#  listAllPcloudUsers
#  addShUserToPcloud
  createSourceSecretStore
}

####################################################
addShUserToPcloud() {
  # The Secrets Hub user is created as a Vault user
  CYBERARK_ADMIN_USER=$INSTALLERUSER
  CYBERARK_ADMIN_PWD=$INSTALLERUSER_PASSWORD

  sessionToken=$($CYBRVAULT_CLI session_token_get)
  $CURL -X POST							\
	$VAULT_API_URL/Users/					\
        --header "Content-Type: application/json"       	\
        --header "Authorization: $sessionToken"			\
	--data "{						\
		\"username\":\"SecretsHub\",			\
		\"userType\": \"DAPService\",			\
		\"initialPassword\": \"$SECRETS_HUB_PASSWORD\",	\
		\"authenticationMethod\": [\"AuthTypePass\"],	\
		\"enableUser\": true,				\
		\"changePassOnNextLogon\": false,		\
		\"passwordNeverExpires\": true,			\
		\"distinguishedName\": \"\",			\
		\"description\": \"\"				\
	}" | jq .
}

####################################################
listAllPcloudUsers() {
  # Lists users in PrivilegeCloud, not in Identity
  CYBERARK_ADMIN_USER=$INSTALLERUSER
  CYBERARK_ADMIN_PWD=$INSTALLERUSER_PASSWORD

  sessionToken=$($CYBRVAULT_CLI session_token_get)
  $CURL -X GET						\
	$VAULT_API_URL/Users/				\
        --header "Content-Type: application/json"      	\
        --header "Authorization: $sessionToken" | jq .
}

####################################################
createSourceSecretStore() {
  authToken=$($CYBRVAULT_CLI auth_token_get)
  $CURL -X POST		\
	$SECRETS_HUB_URL/secret-stores				\
	--write-out '\nHTTP-CODE: %{http_code}\n'		\
        --header "Content-Type: application/json"       	\
        --header "Authorization: Bearer $authToken"		\
	--data "{						\
		  \"name\": \"Privilege Cloud\",		\
		  \"description\":\"pam\",			\
		  \"type\":\"PAM_PCLOUD\",			\
		  \"data\": {					\
		    \"url\": \"$VAULT_BASE_URL\",		\
		    \"userName\": \"SecretsHub\",		\
		    \"password\": \"$SECRETS_HUB_PASSWORD\"	\
		  }						\
		}"
}

main "$@"
