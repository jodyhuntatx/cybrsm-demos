#!/bin/bash

source demo-vars.sh

export CURL="curl -sk"

# Parameters
exportPlatformId=${1:-"MySQL"}
importPlatformId=${2:-"Test-MySQL-DualAccts"}
rotationPlatformId=${3:-"MySQL-RotationGroup"}

#####################################
main() { 
#  pcloud_authenticate
  installeruser_authenticate
#  export_platform
#  import_rotationgroup_platform
  import_account_platform
}

#####################################
export_platform() {
  rm -f ./export/*
  $CURL -X POST 							\
	        --header "$authHeader"					\
	        --header "Content-Type: application/json"		\
	        "${PCLOUD_URL}/platforms/$exportPlatformId/export"	\
		-d ""							\
		> "./export/${exportPlatformId}.zip"
}

#####################################
import_rotationgroup_platform() {
  instantiate_rotationgroup_platform
  importArray=$(base64 -i ./import/$rotationPlatformId.zip)
  import_platform
}

#####################################
instantiate_rotationgroup_platform() {
  rm -f ./import/*
  cat ./templates/Policy-RotationalGroupTemplate.ini			\
  | sed -e "s#{{ ROTATIONAL_GROUP_NAME }}#$rotationPlatformId#g"	\
  > ./import/Policy-$rotationPlatformId.ini

  cat ./templates/Policy-RotationalGroupTemplate.xml			\
  | sed -e "s#{{ ROTATIONAL_GROUP_NAME }}#$rotationPlatformId#g"	\
  > ./import/Policy-$rotationPlatformId.xml

  # Import to the vault does not like path prefixes in zipfile
  cd ./import	
    zip $rotationPlatformId.zip Policy-$rotationPlatformId.*
  cd ..
}

#####################################
import_account_platform() {
  instantiate_account_platform
  importArray=$(base64 -i ./import/$importPlatformId.zip)
  import_platform
}

#####################################
instantiate_account_platform() {
  rm -f ./import/*
  cat ./templates/Policy-DualAcctTemplate-MySQL.ini	\
  | sed -e "s#{{ PLATFORM_ID }}#$importPlatformId#g"	\
  > ./import/Policy-$importPlatformId.ini

  cat ./templates/Policy-DualAcctTemplate-MySQL.xml	\
  | sed -e "s#{{ PLATFORM_ID }}#$importPlatformId#g"	\
  > ./import/Policy-$importPlatformId.xml

  # Import to the vault does not like path prefixes in zipfile
  cd ./import	
    zip $importPlatformId.zip Policy-$importPlatformId.*
  cd ..
}

#####################################
# called by import_<account-type>_platform functions
import_platform() {
  response=$($CURL -X POST 					\
		--write-out '\n%{http_code}'			\
	        --header "$authHeader"				\
	        --header "Content-Type: application/json"	\
	        "${PCLOUD_URL}/platforms/import"		\
		--data "{					\
			\"ImportFile\": \"$importArray\"	\
		    }")
  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    201)
        echo "$content"
       ;;
    *)
	echo "Error - http_code: $http_code"
        echo "$content"
       ;;
  esac

}

#####################################
# sets the global authorization header used in api calls for other methods
function pcloud_authenticate() {
  $util_defaults
  echo "Authenticating user $CYBERARK_ADMIN_USER..."
  response=$($CURL 							\
        -X POST 							\
       	--write-out '\n%{http_code}'                      		\
        https://$IDENTITY_TENANT_ID.id.cyberark.cloud/oauth2/platformtoken \
        -H "Content-Type: application/x-www-form-urlencoded"      	\
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CYBERARK_ADMIN_USER"		\
        --data-urlencode "client_secret"="$CYBERARK_ADMIN_PWD")
  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    200)
	jwToken=$(echo $content| jq -r .access_token)
  	authHeader="Authorization: Bearer $jwToken"
        ;;
    *)
        echo "Error code $http_code when authenticating $CYBERARK_ADMIN_USER."
        echo $content
        exit -1
        ;;
  esac
}

#####################################
# authns legacy installeruser for non-CyberArk Identity vault access
function installeruser_authenticate() {
  response=$($CURL -X POST 						\
       		    --write-out '\n%{http_code}'                      	\
	           --header "Content-Type: application/json"		\
	           --data "{\"username\":\"$INSTALLERUSER\",	 	\
		            \"password\":\"$INSTALLERUSER_PASSWORD\"}"	\
	           "${PCLOUD_URL}/auth/Cyberark/Logon/")
  http_code=$(tail -n1 <<< "$response")  # get http_code on last line
  content=$(sed '$ d' <<< "$response")   # trim http_code

  case $http_code in
    200)
	sessionToken=$(echo $content | tr -d '"')
	authHeader="Authorization: $sessionToken"
	;;
    *)	
	echo "Error code $http_code when authenticating $INSTALLERUSER."
	echo $content
	exit -1
	;;
  esac
}

main "$@"
