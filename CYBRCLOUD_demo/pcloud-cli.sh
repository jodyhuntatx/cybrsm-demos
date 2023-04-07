#!/bin/bash

pcloudUrl=https://cybr-secrets.privilegecloud.cyberark.cloud
identityAdminUrl=https://aao4987.id.cyberark.cloud

###############################
showUsage() {
    echo "Usage:"
    echo "     $0 [ safes | users | apps ]"
    echo "     $0 [ safe <safe-name> | userInfo <user-name> | user <user-app-name> | app <app-id> ]"
    echo "     $0 [ app-add <app-id> ]"
    echo "     $0 [ app-delete <unique-user-id> ]"
    echo "     $0 [ safe-member-add <unique-safe-id> <member-name> ]"
    exit -1
}

###############################
main() {
  local command=$1

  case $command in
    safes | users | apps)
	;;
    safe | userInfo | user | app | app-add | app-delete)
	if [ $# != 2 ]; then
	  showUsage
	fi
	nameSpec=$2
	;;
    safe-member-add)
	if [ $# != 3 ]; then
	  showUsage
	fi
	safeId=$2
	memberName=$3
	;;
    *)	showUsage
	;;
  esac

  case $command in
    safes)
	jwToken=$(./cybrid-cli.sh token)
	curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Safes/		\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken"	\
	| jq .
	;;
    users)
        jwToken=$(./cybrid-cli.sh token)
        curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Users/		\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken"	\
	| jq .
        ;;
    safe)
	jwToken=$(./cybrid-cli.sh token)
	curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Safes/$nameSpec	\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken"	\
	| jq .
	;;
    user)
	jwToken=$(./cybrid-cli.sh token)
        curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Users/		\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken"	\
	| jq -r ".Users[] | select(.username==\"$nameSpec\")"
	;;
    userInfo)
	jwToken=$(./cybrid-cli.sh token)
	curl -sk \
          --request POST				\
	  $identityAdminUrl/UserMgmt/GetUserInfo	\
	  --header 'Content-Type: application/json'	\
	  --header "Authorization: Bearer $jwToken"	\
	  --data "{					\
                \"ID\":\"$nameSpec\"			\
		}"					\
	| jq .
	;;
    apps)
        jwToken=$(./cybrid-cli.sh token)
        curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/WebServices/PIMServices.svc/Applications \
          --header "Content-Type: application/json"     \
          --header "Authorization: Bearer $jwToken"	\
	| jq .
        ;;
    app)
        jwToken=$(./cybrid-cli.sh token)
        curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/WebServices/PIMServices.svc/Applications/$nameSpec \
          --header "Content-Type: application/json"     \
          --header "Authorization: Bearer $jwToken"	\
	| jq .
        ;;
    app-add)
	jwToken=$(./cybrid-cli.sh token)
	curl -sk \
          --request POST				\
	  $pcloudUrl/PasswordVault/API/Users		\
	  --header 'Content-Type: application/json'	\
	  --header "Authorization: Bearer $jwToken"	\
	  --data "{					\
                \"username\":\"$nameSpec\",		\
                \"userType\":\"AIMAccount\",		\
                \"initialPassword\":\"RanD@mn355\",	\
                \"componentUser\": false,		\
                \"passwordNeverExpires\": true,		\
                \"changePassOnNextLogon\": false 	\
		}"					\
	| jq .
	;;
    app-delete)
	jwToken=$(./cybrid-cli.sh token)
	curl -sk \
          --request DELETE				\
	  $pcloudUrl/PasswordVault/API/Users/$nameSpec	\
	  --header 'Content-Type: application/json'	\
	  --header "Authorization: Bearer $jwToken"	\
	| jq .
	;;
    safe-member-add)
	jwToken=$(./cybrid-cli.sh token)
	curl -sk \
          --request POST					\
	  $pcloudUrl/PasswordVault/API/Safes/${safeId}/Members/ \
	  --header 'Content-Type: application/json'		\
	  --header "Authorization: Bearer $jwToken"		\
	  --data "{						\
                \"memberName\":\"$memberName\",			\
                \"memberType\":\"User\",			\
		\"permissions\": {				\
			\"useAccounts\":true,			\
			\"retrieveAccounts\": true,		\
			\"listAccounts\": true,			\
			\"accessWithoutConfirmation\": true	\
			}					\
		}"						\
	| jq .
	;;
    *)
	showUsage
	;;
  esac
}

main "$@"
