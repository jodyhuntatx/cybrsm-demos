#!/bin/bash

# use 'curl -v' and 'set -x' for verbose debugging 
CURL="curl -sk"
util_defaults="set -u"

TRACE=true

###############################
showUsage() {
    echo "Usage:"
    echo "  $0 user_list"
    echo "  $0 user_create <identity-display-name> <password> <description>"
    echo "  $0 [ user_get | user_roles_get | user_remove ] <identity-display-name>"
    echo "  $0 user_role_add <identity-display-name> <role-name>"
    echo "  $0 roles_get"
    echo "  $0 role_id_get <role-name>"
    echo "  $0 role_get <role-name>"
    echo "  $0 setAttribute <identity-display-name> <attr-name> <attr-value>"
    echo "  $0 describe_system"
    echo "  $0 tenant_info"
    echo "  $0 suffix_list"
    echo "  $0 suffix_create <tenant-suffix>"
    echo "  $0 advance_tenant_info"
    exit -1
}

###############################
main() {
  local command=$1
  uName=""

  case $command in
    user_list | roles_get | describe_system | tenant_info | advanced_tenant_info| suffix_list) 
      ;;
    user_create)
      if [[ $# != 4 ]]; then
        showUsage
      fi
      uName=$2
      uPwd=$3
      uDesc="$4"
      ;;
    user_get | user_roles_get | user_remove)
      if [[ $# != 2 ]]; then
        showUsage
      fi
      uName=$2
      ;;
    user_role_add)
      if [[ $# != 3 ]]; then
        showUsage
      fi
      uName=$2
      roleName=$3
      ;;
    role_id_get | role_get)
      if [[ $# != 2 ]]; then
        showUsage
      fi
      roleName=$2
      ;;
    suffix_create | suffix_delete)
      if [[ $# != 2 ]]; then
        showUsage
      fi
      suffix=$2
      ;;
    *)
      showUsage
  esac

  oauthClientAuthenticate

  $command
}

###############################
describe_system() {
  $util_defaults

  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/SysInfo/About		\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "$authHeader"				\
  --data ''
}

###############################
user_list() {
  $util_defaults

  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/CDirectoryService/GetUsers	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "$authHeader"				\
  --data ''
#						\
#  | jq .Result.Results
}

###############################
user_create() {
  $util_defaults
  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/CDirectoryService/CreateUser	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "$authHeader"				\
  --data "{						\
		\"Name\":\"$uName\",			\
		\"Password\":\"$uPwd\",			\
		\"Description\":\"$uDesc\",		\
		\"InEverybodyRole\":\"false\",		\
		\"ServiceUser\":\"false\",		\
		\"ForcePasswordChangeNext\":\"false\",	\
		\"PasswordNeverExpire\":\"true\",	\
		\"SendEmailInvite\":\"false\"	\
	}"
}

###############################
user_remove() {
  $util_defaults
  $CURL --request POST				\
  --url $CYBERARK_IDENTITY_URL/UserMgmt/RemoveUser 	\
  --header 'Accept: */*'			\
  --header 'Content-Type: application/json'	\
  --header 'X-IDAP-NATIVE-CLIENT: true'		\
  --header "$authHeader"			\
  --data "{					\
		\"ID\":\"$uName\"		\
	}"
}

###############################
user_get() {
  $util_defaults
  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/UserMgmt/GetUserInfo		\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "$authHeader"				\
  --data "{						\
		\"ID\":\"$uName\"			\
	}"
}

###############################
user_roles_get() {
  $util_defaults
  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/UserMgmt/GetUsersRolesAndAdministrativeRights \
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "$authHeader"				\
  --data "{						\
		\"ID\":\"$uName\"			\
	}"						\
  | jq .Result.Results
}

###############################
user_role_add() {
  $util_defaults

  roleId=$(role_id_get)

  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/Roles/UpdateRole		\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "$authHeader"				\
  --data "{ \"Name\": \"$roleId\",			\
	    \"Users\": { \"Add\": [ \"$uName\" ] }	\
          }"
}

###############################
tenant_info() {
  $util_defaults

  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/TenantConfig/GetCustomerConfig \
  --header 'Accept: */*'				\
  --header "$authHeader"				\
  --data ''						\
  | jq .
}

###############################
advanced_tenant_info() {
  $util_defaults

  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/TenantConfig/GetAdvancedConfig \
  --header 'Accept: */*'				\
  --header "$authHeader"				\
  --data ''						\
  | jq .
}

###############################
roles_get() {
  $util_defaults

  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/RedRock/query		\
  --header 'Accept: */*'				\
  --header "$authHeader"				\
  --data "{'Script': 'select * from Role;'}"		\
  | jq .Result.Results
}

###############################
role_id_get() {
  $util_defaults
  printf -v query '.[] | select(.Row.Name=="%s").Row.ID' "$roleName"
  echo $(roles_get) | jq -r "$query"
}

###############################
role_get() {
  $util_defaults
  roleId=$(role_id_get)
  $CURL --request POST		\
  --url $CYBERARK_IDENTITY_URL/Roles/GetRole?Name=${roleId}\&SuppressPrincipalsList=false\&getRights=false	\
  --header 'accept: */*'	\
  --header "$authHeader"	\
  --data ''
}

###############################
suffix_list() {
  $util_defaults
  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/Core/GetAliasesForTenant \
  --header 'accept: */*'				\
  --header "$authHeader"				\
  --data ''
}

###############################
suffix_create() {
oldName="cyberark.cloud.18478"
domain="abf4850.id.cyberark.cloud"

  $util_defaults
  $CURL --request POST				\
  --url $CYBERARK_IDENTITY_URL/Core/StoreAlias	\
  --header 'accept: */*'			\
  --header 'Content-Type: application/json'	\
  --header "$authHeader"			\
  --data "{					\
 		\"alias\": \"$suffix\",		\ 
		\"cdsAlias\": \"true\",		\ 
		\"domain\": \"$domain\",	\ 
		\"oldName\": \"$oldName\"	\ 
	}"

}

###############################
setAttribute() {
  $util_defaults
  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/UserMgmt/ChangeUserAttributes	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --header "$authHeader"				\
  --data "{						\
		\"ID\":\"$uName\",			\
		\"$aKey\":\"$aVal\"
	}"
}

#####################################
# sets the global authorization header used in api calls for other methods
function oauthClientAuthenticate() {
  $util_defaults
#  echo "Authenticating user $CYBERARK_ADMIN_USER..."
  AUTH_TOKEN=$($CURL                                             	\
        -X POST                                                         \
        "${CYBERARK_IDENTITY_URL}/oauth2/platformtoken"        		\
        -H "Content-Type: application/x-www-form-urlencoded"            \
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CYBERARK_ADMIN_USER"             \
        --data-urlencode "client_secret"="$CYBERARK_ADMIN_PWD"          \
        | jq -r .access_token)
  authHeader="Authorization: Bearer $AUTH_TOKEN"
}

###############################
# Authenticates with password and sets global variable AUTH_TOKEN
#
startAdvanceAuthenticate() {
  $util_defaults
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
  $util_defaults
  local uname=$1; shift

  $CURL --request POST					\
  --url $CYBERARK_IDENTITY_URL/Security/StartAuthentication	\
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
  $util_defaults
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
  --url $CYBERARK_IDENTITY_URL/Security/AdvanceAuthentication	\
  --header 'Accept: */*'				\
  --header 'Content-Type: application/json'		\
  --header 'X-IDAP-NATIVE-CLIENT: true'			\
  --data "$pkg"
}

#########################
# saved for later use
advanceSMS() {
  $util_defaults
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
  $util_defaults
  local res=$1; shift
  local funcName=$1; shift

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
