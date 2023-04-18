#!/bin/bash

pcloudUrl=https://cybr-secrets.privilegecloud.cyberark.cloud
identityAdminUrl=https://aao4987.id.cyberark.cloud

###############################
showUsage() {
    echo "Usage:"
    echo "  $0 [ safes | safe <safe-name> | safe-member-add <safe-name> <member-name> ]"
    echo "  $0 [ accts | acct <account-name> ]"
    echo "  $0 [ users | user <user-name> | userId <unique-id> | userFromISPSS <user-name> ]"
    echo "  $0 [ apps | app <app-name> | app-add <app-name> | app-delete <unique-id> ]"
    exit -1
}

###############################
main() {
  local command=$1

  case $command in
    safes | accts | users | apps)
	;;
    safe | acct | userFromISPSS | user | app | app-add | app-delete | userId)
	if [ $# != 2 ]; then
	  showUsage
	fi
	nameSpec=$2
	;;
    safe-member-add)
	if [ $# != 3 ]; then
	  showUsage
	fi
	safeName=$2
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
    safe)
	jwToken=$(./cybrid-cli.sh token)
	curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Safes/$nameSpec	\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken"	\
	| jq .
	;;
    accts)
        jwToken=$(./cybrid-cli.sh token)
        curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Accounts/	\
          --header "Content-Type: application/json"     \
          --header "Authorization: Bearer $jwToken"     \
        | jq .
        ;;
    acct)
        jwToken=$(./cybrid-cli.sh token)
        curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Accounts?Search=$nameSpec	\
          --header "Content-Type: application/json"     		\
          --header "Authorization: Bearer $jwToken"     		\
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
    user)
	jwToken=$(./cybrid-cli.sh token)
        curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Users?Search=$nameSpec	\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken"	\
	| jq .
	;;
    userId)
	jwToken=$(./cybrid-cli.sh token)
        curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Users/$nameSpec	\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken"	\
	| jq .
	;;
    userFromISPSS)
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
	  $pcloudUrl/PasswordVault/API/Safes/${safeName}/Members/ \
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
