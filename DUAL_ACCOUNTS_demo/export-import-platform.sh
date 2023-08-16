#!/bin/bash

source demo-vars.sh

export CURL="curl -sk"


#####################################
main() { 
  if $SELF_HOSTED_PAM; then
    installeruser_authenticate	# sets global variable authHeader
  else
    pcloud_authenticate	# sets global variable authHeader
  fi
  
#  export_platform
  import_rotationgroup_platform
  import_account_platform
}

#####################################
export_platform() {
  rm -f ./export/*
  $CURL -X POST 							\
	        --header "$authHeader"					\
	        --header "Content-Type: application/json"		\
	        "${PCLOUD_URL}/platforms/$exportAccountPlatformId/export"	\
		-d ""							\
		> "./export/${exportAccountPlatformId}.zip"
}

#####################################
import_rotationgroup_platform() {
  instantiate_rotationgroup_platform
  importArray=$(base64 -i ./import/$rotationGroupPlatformId.zip)
  import_platform
}

#####################################
instantiate_rotationgroup_platform() {
  rm -f ./import/*
  cat ./templates/Policy-RotationalGroupTemplate.ini			\
  | sed -e "s#{{ ROTATIONAL_GROUP_NAME }}#$rotationGroupPlatformId#g"	\
  > ./import/Policy-$rotationGroupPlatformId.ini

  cat ./templates/Policy-RotationalGroupTemplate.xml			\
  | sed -e "s#{{ ROTATIONAL_GROUP_NAME }}#$rotationGroupPlatformId#g"	\
  > ./import/Policy-$rotationGroupPlatformId.xml

  # Import to the vault does not like path prefixes in zipfile
  cd ./import	
    zip $rotationGroupPlatformId.zip Policy-$rotationGroupPlatformId.*
  cd ..
}

#####################################
import_account_platform() {
  instantiate_account_platform
  importArray=$(base64 -i ./import/$dualAccountPlatformId.zip)
  import_platform
}

#####################################
instantiate_account_platform() {
  rm -f ./import/*
  cat ./templates/Policy-DualAcctTemplate-MySQL.ini	\
  | sed -e "s#{{ PLATFORM_ID }}#$dualAccountPlatformId#g"	\
  > ./import/Policy-$dualAccountPlatformId.ini

  cat ./templates/Policy-DualAcctTemplate-MySQL.xml	\
  | sed -e "s#{{ PLATFORM_ID }}#$dualAccountPlatformId#g"	\
  > ./import/Policy-$dualAccountPlatformId.xml

  # Import to the vault does not like path prefixes in zipfile
  cd ./import	
    zip $dualAccountPlatformId.zip Policy-$dualAccountPlatformId.*
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
  #echo "Authenticating user $CYBERARK_ADMIN_USER..."
  jwToken=$(./pcloud-cli.sh auth_token_get)
  authHeader="Authorization: Bearer $jwToken"
}

#####################################
# authns legacy installeruser for non-CyberArk Identity vault access
function installeruser_authenticate() {
  sessionToken=$(./pcloud-cli.sh session_token_get)
  authHeader="Authorization: $sessionToken"
}

main "$@"
