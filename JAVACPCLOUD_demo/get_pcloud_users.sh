#!/bin/bash

CURL="curl -sk"
TENANT_SUFFIX=3357
PCLOUD_ADMIN_USER=installeruser@cyberark.cloud.$TENANT_SUFFIX
PCLOUD_ADMIN_PASSWORD=FooBarBaz1234
PCLOUD_API_URL=https://cybr-secrets.privilegecloud.cyberark.cloud

sessionToken=$($CURL -X POST	\
	$PCLOUD_API_URL/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon	\
        --header "Content-Type: application/json"       						\
	--data "{ \"username\":\"$PCLOUD_ADMIN_USER\",\"password\":\"$PCLOUD_ADMIN_PASSWORD\"}"	\
	| jq -r .CyberArkLogonResult)

$CURL -X GET		\
	$PCLOUD_API_URL/PasswordVault/API/Users/		\
        --header "Content-Type: application/json"       	\
        --header "Authorization: $sessionToken" | jq .
