#!/bin/bash

pcloudUrl=https://cybr-secrets.privilegecloud.cyberark.cloud
identityAdminUrl=https://aao4987.id.cyberark.cloud

###############################
showUsage() {
    echo "Usage:"
    echo "     $0 [ safes | users ]"
    echo "     $0 [ safe <safe-name> | user <user-name> ]"
    exit -1
}

###############################
main() {
  local command=$1

  case $command in
    safes)
	;;
    safe | user)
	if [ $# != 2 ]; then
	  showUsage
	fi
	nameSpec=$2
	;;
    *)	showUsage
	;;
  esac

  case $command in
    safes)
	jwToken=$(./cybrid.sh token)
	curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Safes/             \
          --header "Content-Type: application/json"       \
          --header "Authorization: Bearer $jwToken"       | jq .
	;;
    safe)
	jwToken=$(./cybrid.sh token)
	curl -sk \
          --request GET \
          $pcloudUrl/PasswordVault/API/Safes/$nameSpec	\
          --header "Content-Type: application/json"	\
          --header "Authorization: Bearer $jwToken"       | jq .
	;;
    user)
	jwToken=$(./cybrid.sh token)
	curl -sk \
          --request POST				\
	  $identityAdminUrl/UserMgmt/GetUserInfo	\
	  --header 'Content-Type: application/json'	\
	  --header "Authorization: Bearer $jwToken"	\
	  --data "{					\
                \"ID\":\"$nameSpec\"			\
          }"	| jq .
	;;
    *)
	showUsage
	;;
  esac
}

main "$@"
