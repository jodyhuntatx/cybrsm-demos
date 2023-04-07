#!/bin/bash

source ./demovars.sh

CURL="curl -s"
TRACE=false

###############################
showUsage() {
    echo "Usage:"
    echo "     $0 [ list | meta | keys | token | token_sa ]"
    echo "     $0 [ create | get | remove ] <user-login-name>"
    echo "     $0 setAttribute <user-login-name> <attr-name> <attr-value>"
    exit -1
}

###############################
main() {
  if [[ $# < 1 ]]; then showUsage; fi

  local command=$1
  uName=""
  case $command in
    list | meta | keys | token | token_sa)
	;;
    create | get | remove)
	uName="$2@$IDENTITY_DOMAIN"
	;;
    setAttribute)
	uName="$2@$IDENTITY_DOMAIN"
	attrKey=$3
	attrVal=$4
	;;
    *)	showUsage
	;;
  esac

  AUTH_TOKEN=$(getOauthToken $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD)

  case $command in
    list)
	echo "Listing users"
	listResult=$(listUsers $AUTH_TOKEN)
	test "$listResult" "listUsers"
	echo "$listResult" | jq .
	;;
    create)
	echo "Creating user: $uName"
	createResult=$(createUser $AUTH_TOKEN $uName)
	test "$createResult" "createUser-$uName"
	;;
    get)
	echo "Getting info for: $uName"
	getResult=$(getUserInfo $uName)
	test "$getResult" "getUserInfo"
	echo $getResult | jq .
	;;
    remove)
	echo "Removing user: $uName"
	removeResult=$(removeUser $AUTH_TOKEN $uName)
	test "$removeResult" "removeUser-$uName"
	;;
    setAttribute)
	echo "Setting attribute $attrKey to $attrVal for user $uName:"
        setAttrResult=$(setAttribute $AUTH_TOKEN $uName $attrKey $attrVal)
        test "$setAttrResult" "setAttribute-$uName-$attrKey-$attrVal"
	;;
    meta)
        getMetaData $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD $IDENTITY_APP_ID
        exit
        ;;
    keys)
        getPubKeys $IDENTITY_APP_ID
        exit
        ;;
    token_sa)
        getAuthToken $IDENTITY_ADMIN_USER $IDENTITY_ADMIN_PWD
        exit
        ;;
    token)
	echo $AUTH_TOKEN
        ;;
    *)
	showUsage
	;;
  esac
}

###############################
# Authenticates w/ user creds to get platform JWT
#
getOauthToken() {
  local uName=$1; shift
  local uPwd=$1; shift

  $CURL	\
	-X POST	\
	https://$IDENTITY_TENANT_ID.id.cyberark.cloud/oauth2/platformtoken \
	--header "Content-Type: application/x-www-form-urlencoded"	\
	--data-urlencode "grant_type"="client_credentials"		\
	--data-urlencode "client_id"="$uName"				\
	--data-urlencode "client_secret"="$uPwd" | jq -r .access_token
  
}

###############################
# Authenticates with start/advance workflow
#
getAuthToken() {
  local uName=$1; shift
  local uPwd=$1; shift

  # Start authentication
  if $TRACE; then
    echo "Logging in as $uName:"
  fi
  sessionResult=$(startAuthentication $uName)
  test "$sessionResult" "startAuthentication" fatal

  sessionId=$(echo $sessionResult | jq -r .Result.SessionId)

  # Submit password
  mechanismName=$(echo $sessionResult | jq -r .Result.Challenges[0].Mechanisms[0].Name)
  if $TRACE; then
    echo "Advancing authn: $mechanismName..."
  fi
  mechanismId=$(echo $sessionResult | jq -r .Result.Challenges[0].Mechanisms[0].MechanismId)
  advanceResult=$(advanceAuthentication $IDENTITY_TENANT_ID $sessionId $mechanismId "Answer" $uPwd)
  test "$advanceResult" "advanceAuthentication-$mechanismName" fatal
  echo $advanceResult | jq -r .Result.Token
}

###############################
startAuthentication() {
  local uname=$1; shift

  $CURL --request POST					\
  --url $IDENTITY_URL/Security/StartAuthentication	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --data "{						\
		\"TenantId\":\"$IDENTITY_TENANT_ID\",	\
		\"User\":\"$uname\",			\
		\"Version\":\"1.0\"			\
	}"
}

###############################
advanceAuthentication() {
  local tenantId=$1; shift
  local sessId=$1; shift
  local mechId=$1; shift
  local act=$1; shift
  local answer=$1; shift

  ANSWERPKG="{						\
		\"TenantId\":\"$tenantId\",		\
		\"SessionId\":\"$sessId\",		\
		\"MechanismId\":\"$mechId\",		\
		\"Action\":\"$act\",			\
		\"Answer\":\"$answer\"			\
	}"
  NOANSWERPKG="{					\
		\"TenantId\":\"$tenantId\",		\
		\"SessionId\":\"$sessId\",		\
		\"MechanismId\":\"$mechId\",		\
		\"Action\":\"$act\"			\
	}"

  if [[ "$answer" == "" ]]; then
    pkg="$NOANSWERPKG"
  else
    pkg="$ANSWERPKG"
  fi

  $CURL --request POST					\
  --url $IDENTITY_URL/Security/AdvanceAuthentication	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --data "$pkg"
}

###############################
listUsers() {
  local authTkn=$1; shift

  $CURL --request POST					\
  	$IDENTITY_URL/CDirectoryService/GetUsers	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header "Authorization: Bearer $authTkn"		\
  --data ""
  # data pkg of length 0 ("") works around "411 - Length Required" errors
}

###############################
createUser() {
  local authTkn=$1; shift
  local uName=$1; shift

  read -s -p "Enter user password: " uPwd
  echo
  read -s -p "Enter description of user: " uDesc
  echo
  $CURL --request POST					\
  --url $IDENTITY_URL/CDirectoryService/CreateUser	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "Authorization: Bearer $authTkn"		\
  --data "{						\
		\"Name\":\"$uName\",			\
		\"Password\":\"$uPwd\",			\
		\"Description\":\"$uDesc\",		\
		\"InEverybodyRole\":\"false\",		\
		\"ServiceUser\":\"true\",		\
		\"OauthClient\": true,		\
		\"ForcePasswordChangeNext\":\"false\",	\
		\"PasswordNeverExpire\":\"true\",	\
		\"SendEmailInvite\":\"false\"	\
	}"
}

###############################
removeUser() {
  local authTkn=$1; shift
  local uName=$1; shift

  $CURL --request POST				\
  --url $IDENTITY_URL/UserMgmt/RemoveUser 	\
  --header 'Accept: */*'			\
  --header 'Content-Type: application/json'	\
  --header 'X-IDAP-NATIVE-CLIENT: true'		\
  --header "Authorization: Bearer $authTkn"	\
  --data "{					\
		\"ID\":\"$uName\"		\
	}"
}

###############################
setAttribute() {
  local authTkn=$1; shift
  local uName=$1; shift
  local aKey=$1; shift
  local aVal=$1; shift

  $CURL --request POST					\
  --url $IDENTITY_URL/UserMgmt/ChangeUserAttributes	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "Authorization: Bearer $authTkn"		\
  --data "{						\
		\"ID\":\"$uName\",			\
		\"$aKey\":\"$aVal\"
	}"
}

###############################
# gets metadata of OAuth2 provider
# https://identity-developer.cyberark.com/reference/post_oauth2-getmeta
#
getMetaData() {
  local uName=$1; shift
  local uPwd=$1; shift
  local appId=$1; shift

  auth_creds=$(echo $uName:$uPwd | base64)

set -x
  $CURL --request POST                                          \
        --url $IDENTITY_URL/OAuth2/GetMeta?serviceName=$appId	\
        --header 'Accept: */*'                                  \
        --header 'Content-Type: application/json'               \
        --header "Authorization Basic $auth_creds"              \
        --data ''
}

###############################
# gets public keys of Oauth2 provider
# https://identity-developer.cyberark.com/reference/post_oauth2-keys-app-id
#
getPubKeys() {
  local appId=$1; shift

  $CURL --request POST                                          \
        --url $IDENTITY_URL/OAuth2/keys/$appId			\
        --header 'Accept: */*'                                  \
        --header 'Content-Type: application/json'               \
        --data ''
}

###############################
# gets user info
# https://identity-developer.cyberark.com/v3.0/reference/post_cdirectoryservice-getuserbyname
#
getUserInfo() {
  local local_uName=$1; shift
  $CURL --request POST						\
        --url $IDENTITY_URL/CDirectoryService/GetUserByName	\
        --header 'Accept: */*'					\
        --header 'Content-Type: application/json'		\
        --header "Authorization: Bearer $AUTH_TOKEN"		\
        --data "{ \"username\": \"$local_uName\" }"
}

###############################
test() {
  local res=$1; shift
  local funcName=$1; shift
  local fatal=$1; shift

  if $TRACE; then
    echo "------------------------------"
    echo "$funcName result:"
    echo $res | jq .
    echo "------------------------------"
  fi

  if [[ "$(echo $res | jq .success)" != "true" ]]; then
    echo "------------------------------"
    echo "$funcName failed with result:"
    echo $res
    echo "------------------------------"
    if [[ "$fatal" == "fatal" ]]; then
      echo "Fatal error. Exiting..."
      exit -1
    fi
  fi
}

main "$@"
