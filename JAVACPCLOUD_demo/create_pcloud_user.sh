#!/bin/bash

SECRETS_HUB_PASSWORD=Cyberark1

TENANT_NAME=cybr-secrets
TENANT_SUFFIX=3357
PCLOUD_ADMIN_USER=installeruser@cyberark.cloud.$TENANT_SUFFIX
PCLOUD_ADMIN_PASSWORD=<installeruser-password>
PCLOUD_API_URL=https://$TENANT_NAME.privilegecloud.cyberark.cloud

SECRETS_HUB_URL=https://$TENANT_NAME-secrets_hub.cyberark.cloud/api/secret-stores
SECRETS_HUB_SESSION_TOKEN="<paste-token-here>"

CURL="curl -sk"

main() {
  listAllPcloudUsers
#  addUserToPcloud
#  connectPcloudToSecretsHub
}

####################################################
getPcloudSessionToken() {
  # authenticate, get session token
  sessionToken=$($CURL -X POST	\
	$PCLOUD_API_URL/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon	\
        --header "Content-Type: application/json"       						\
	--data "{ \"username\":\"$PCLOUD_ADMIN_USER\",\"password\":\"$PCLOUD_ADMIN_PASSWORD\"}"	\
	| jq -r .CyberArkLogonResult)
}

####################################################
addUserToPcloud() {
  getPcloudSessionToken
  $CURL -X POST		\
	$PCLOUD_API_URL/PasswordVault/API/Users/		\
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
  getPcloudSessionToken
  $CURL -X GET		\
	$PCLOUD_API_URL/PasswordVault/API/Users/		\
        --header "Content-Type: application/json"       	\
        --header "Authorization: $sessionToken" | jq .
}

####################################################
connectPcloudToSecretsHub() {
  $CURL -X POST		\
	$SECRETS_HUB_URL					\
        --header "Content-Type: application/json"       	\
        --header "Authorization: $SECRETS_HUB_SESSION_TOKEN"	\
	--data "{						\
		  \"name\": \"Privilege Cloud\",		\
		  \"description\":\"pam\",			\
		  \"type\":\"PAM_PCLOUD\",			\
		  \"data\": {					\
		    \"url\": \"$PCLOUD_API_URL/PasswordVault\",	\
		    \"userName\": \"SecretsHub\",		\
		    \"password\": \"$SECRETS_HUB_PASSWORD\"	\
		  }						\
		}"
}

main "$@"
