#!/bin/bash

CURL="curl -sk"
IDENTITY_TENANT_ID=aao4987
IDENTITY_ADMIN_USER=jody_bot@cyberark.cloud.3357
IDENTITY_ADMIN_PASSWORD=$(keyring get cybrid jodybotpwd)
IDENTITY_ADMIN_URL=https://$IDENTITY_TENANT_ID.id.cyberark.cloud
PCLOUD_URL=https://cybr-secrets.privilegecloud.cyberark.cloud

###############################
showUsage() {
    echo "Usage:"
    echo "     $0 [ safes | users ]"
    echo "     $0 [ safe <safe-name> | user <pcloud-user-id> | activate <pcloud-user-id> | enable <pcloud-user-id> ]"
    exit -1
}

###############################
main() {
  local command=$1

  case $command in
    safes | users)
	;;
    safe)
	if [ $# != 2 ]; then
	  showUsage
	fi
	nameSpec=$2
	;;
    user | activate | enable)
	if [ $# != 2 ]; then
	  showUsage
	fi
	userId=$2
	;;
    *)	showUsage
	;;
  esac

  case $command in
    safes)
	jwToken=$(getOauthToken $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD)
	$CURL 		\
          --request GET \
          $PCLOUD_URL/PasswordVault/API/Safes/             \
          --header "Content-Type: application/json"       \
          --header "Authorization: Bearer $jwToken" | jq .
	;;
    users)
	jwToken=$(getOauthToken $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD)
        $CURL		\
          --request GET \
          $PCLOUD_URL/PasswordVault/API/Users/             \
          --header "Content-Type: application/json"       \
          --header "Authorization: Bearer $jwToken" | jq .
        ;;
    safe)
	jwToken=$(getOauthToken $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD)
	$CURL		\
          --request GET \
          $PCLOUD_URL/PasswordVault/API/Safes/$nameSpec	\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken" | jq .
	;;
    user)
	jwToken=$(getOauthToken $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD)
        $CURL           \
          --request GET \
          $PCLOUD_URL/PasswordVault/API/Users/$userId		\
          --header "Content-Type: application/json"             \
          --header "Authorization: Bearer $jwToken" | jq .
        ;;
    activate)
	jwToken=$(getOauthToken $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD)
        $CURL           \
          --request GET \
          $PCLOUD_URL/PasswordVault/API/Users/$userId/Activate	\
          --header "Content-Type: application/json"     	\
          --header "Authorization: Bearer $jwToken" | jq .
        ;;
    enable)
        jwToken=$(getOauthToken $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD)
        $CURL            \
          --request POST \
          $PCLOUD_URL/PasswordVault/API/Users/$userId/enable	\
          --header "Content-Type: application/json"     	\
          --header "Authorization: Bearer $jwToken"		\
	  --data ""
        ;;
    *)
	showUsage
	;;
  esac
}

getOauthToken() {
  local uName=$1; shift
  local uPwd=$1; shift
  $CURL \
	-X POST \
        https://$IDENTITY_TENANT_ID.id.cyberark.cloud/oauth2/platformtoken \
        --header "Content-Type: application/x-www-form-urlencoded"      \
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$uName"                           \
        --data-urlencode "client_secret"="$uPwd" | jq -r .access_token
}

main "$@"
