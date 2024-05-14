#!/bin/bash

CURL="curl -s"
TENANT_ID=aao4987
TENANT_URL=https://$TENANT_ID.id.cyberark.cloud
TENANT_DOMAIN=cyberark.cloud.3357
ADMIN_USER=jody_hunt@$TENANT_DOMAIN
ADMIN_PWD=$(keyring get cybrid admpwd)

DESC="New user testing API creation."

TRACE=true

###############################
showUsage() {
    echo "Usage:"
    echo "     $0 list"
    echo "     $0 [ create | get | remove ] <identity-display-name>"
    echo "     $0 setAttribute <identity-display-name> <attr-name> <attr-value>"
    exit -1
}

###############################
main() {
  if [[ $# < 1 ]]; then showUsage; fi

  local command=$1
  uName=""
  case $# in
    1)	;;
    2)	uName=$2@$TENANT_DOMAIN
	;;
    3)  showUsage
	;;
    4)	uName=$2@$TENANT_DOMAIN
	attrKey=$3
	attrVal=$4
	;;
    *)	showUsage
	;;
  esac

  setAccessToken $ADMIN_USER $ADMIN_PWD

  case $command in
    list)
	echo "Listing users"
	listResult=$(listUsers $AUTH_TOKEN)
	test "$listResult" "listUsers"
	echo $listResult | jq .Result.Results
	;;
    create)
	echo "Creating user: $uName"
	createResult=$(createUser $AUTH_TOKEN $uName $NEW_USER_PWD "$DESC")
	test "$createResult" "createUser-$uName"
	;;
    get)
	echo "Getting user info for: $uName"
	getResult=$(getUserInfo $AUTH_TOKEN $uName)
	test "$getResult" "findUser"
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
    *)
	showUsage
	;;
  esac
}

###############################
# Authenticates with password and sets global variable AUTH_TOKEN
#
setAccessToken() {
  local uName=$1; shift
  local uPwd=$1; shift

  # Start authentication
  echo "Logging in as $uName:"
  sessionResult=$(startAuthentication $uName)
  test "$sessionResult" "startAuthentication" fatal

  sessionId=$(echo $sessionResult | jq -r .Result.SessionId)

  # Submit password
  mechanismName=$(echo $sessionResult | jq -r .Result.Challenges[0].Mechanisms[0].Name)
  echo "Advancing authn: $mechanismName..."
  mechanismId=$(echo $sessionResult | jq -r .Result.Challenges[0].Mechanisms[0].MechanismId)
  advanceResult=$(advanceAuthentication $TENANT_ID $sessionId $mechanismId "Answer" $uPwd)
  test "$advanceResult" "advanceAuthentication-$mechanismName" fatal
  AUTH_TOKEN=$(echo $advanceResult | jq -r .Result.Auth)
}

###############################
startAuthentication() {
  local uname=$1; shift

  $CURL --request POST					\
  --url $TENANT_URL/Security/StartAuthentication	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --data "{						\
		\"TenantId\":\"$TENANT_ID\",		\
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
  --url $TENANT_URL/Security/AdvanceAuthentication	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --data "$pkg"
}

###############################
listUsers() {
  local authTkn=$1; shift

  $CURL --request POST					\
  --url $TENANT_URL/CDirectoryService/GetUsers		\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "Authorization: Bearer $authTkn"		\
  --data ""
  # data pkg of length 0 ("") works around "411 - Length Required" errors
}

###############################
createUser() {
  local authTkn=$1; shift
  local uName=$1; shift
  local uPwd=$1; shift
  local uDesc=$1; shift

  $CURL --request POST					\
  --url $TENANT_URL/CDirectoryService/CreateUser	\
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
  --url $TENANT_URL/UserMgmt/RemoveUser 	\
  --header 'Accept: */*'			\
  --header 'Content-Type: application/json'	\
  --header 'X-IDAP-NATIVE-CLIENT: true'		\
  --header "Authorization: Bearer $authTkn"	\
  --data "{					\
		\"ID\":\"$uName\"		\
	}"
}

###############################
getUserInfo() {
  local authTkn=$1; shift
  local uName=$1; shift

  $CURL --request POST					\
  --url $TENANT_URL/UserMgmt/GetUserInfo		\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "Authorization: Bearer $authTkn"		\
  --data "{						\
		\"ID\":\"$uName\"			\
	}"
}

###############################
setAttribute() {
  local authTkn=$1; shift
  local uName=$1; shift
  local aKey=$1; shift
  local aVal=$1; shift

  $CURL --request POST					\
  --url $TENANT_URL/UserMgmt/ChangeUserAttributes	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "Authorization: Bearer $authTkn"		\
  --data "{						\
		\"ID\":\"$uName\",			\
		\"$aKey\":\"$aVal\"
	}"
}

#########################
# saved for later use
advanceSMS() {
  # Submit SMS request
  msg=$(echo $advanceResult | jq .Message)
  if [[ $msg == null ]]; then
    mechanismName=$(echo $sessionResult | jq -r .Result.Challenges[1].Mechanisms[2].Name)
    echo "Advancing authn: $mechanismName..."
    mechanismId=$(echo $sessionResult | jq -r .Result.Challenges[1].Mechanisms[2].MechanismId)
    advanceResult=$(advanceAuthentication $TENANT_ID $sessionId $mechanismId "StartOOB" )
    test "$advanceResult" "advanceAuthentication-$mechanismName"
  fi
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
