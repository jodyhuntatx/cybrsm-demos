#!/bin/bash

export CURL="curl -sk"

# debugging
util_defaults="set -u"
CONJUR_VERBOSE=${CONJUR_VERBOSE:-""}		# sets CONJUR_VERBOSE to "" if undefined

showUsage() {
  echo "Usage:"
  echo "      $0 [ whoami | resources | list ]"
  echo "      $0 [ get <var-name> ]"
  echo "      $0 [ set <var-name> <var-value> ]"
  echo "      $0 [ append <policy-branch> <policy-file-name> ]"
  echo "      $0 [ update <policy-branch> <policy-file-name> ]"
  echo "      $0 [ enable <authn-type> <service-id> ]"
  echo "      $0 [ status <authn-type> <service-id> ]"
  echo "      $0 issuer_create" 
  echo "      $0 issuer_get" 
  echo "      $0 auth_token_get" 
  exit -1
}

main() {
  checkDependencies

  case $1 in
    whoami | resources | list | issuer_get | issuer_create)
	command=$1
	;;
    get)
	if [[ $# != 2 ]]; then
	  showUsage
	fi
	command=$1
	varName=$2
	;;
    set)
	if [[ $# != 3 ]]; then
	  showUsage
	fi
	command=$1
	varName=$2
	varValue="$3"
	;;
    append | update)
	if [[ $# != 3 ]]; then
	  showUsage
	fi
	command=$1
	policyBranch=$2
	policyFilename=$3
	;;
    enable)
	if [[ $# != 3 ]]; then
	  showUsage
	fi
	command=$1
	authnType=$2
	serviceId=$3
	;;
    status)
	if [[ $# != 3 ]]; then
	  showUsage
	fi
	command=$1
	authnType=$2
	serviceId=$3
	;;
    auth_token_get)
	conjur_authenticate
	echo $authToken
	exit 0
	;;
    *)
	showUsage
	;;
  esac

  conjur_authenticate	# sets global variable authHeader

  case $command in
    issuer_get)
	issuer_get
	;; 
    issuer_create)
	issuer_create
	;; 
    whoami)
	conjur_whoami
	;; 
    resources)
	conjur_resources 
	;;
    list)
	conjur_list 
	;;
    get)
	conjur_get_variable $varName
	;;
    set)
	conjur_set_variable $varName "$varValue"
	;;
    append)
	conjur_append_policy $policyBranch $policyFilename
	;;
    update)
	conjur_update_policy $policyBranch $policyFilename
	;;
    enable)
	conjur_authn_enable $authnType $serviceId
	;;
    status)
	conjur_authn_status $authnType $serviceId
	;;

	# apparently these functions are not implemented in Conjur Cloud
    *)
	showUsage
	;;
  esac

  exit 0

#conjur_rotate_api_key 

}

#####################################
# sets the global authorization header used in api calls for other methods
function conjur_authenticate {
  $util_defaults
  jwToken=$($CURL \
        -X POST \
        $CYBERARK_IDENTITY_URL/oauth2/platformtoken 		\
        -H "Content-Type: application/x-www-form-urlencoded"      	\
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CYBERARK_ADMIN_USER"		\
        --data-urlencode "client_secret"="$CYBERARK_ADMIN_PWD"		\
	| jq -r .access_token)
  authToken=$($CURL	\
        -X POST		\
	$CYBERARK_CCLOUD_API/authn-oidc/cyberark/conjur/authenticate 	\
	-H "Content-Type: application/x-www-form-urlencoded"		\
	-H "Accept-Encoding: base64"					\
	--data-urlencode "id_token=$jwToken" )
  authHeader="Authorization: Token token=\"$authToken\""
}

#####################################
function issuer_get() {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_CCLOUD_API}/issuers/conjur"
}

#####################################
function issuer_create() {
  $util_defaults
  $CURL 							\
	-X POST							\
	-H "$authHeader"					\
	"${CYBERARK_CCLOUD_API}/issuers/conjur"			\
	--data "{						\
		  \"id\": \"jody-aws-issuer\",			\
		  \"max_ttl\": 5000,				\
		  \"type\": \"aws\",				\
		  \"data\": {					\
		    \"access_key_id\": \"my_key_id\",		\
		    \"secret_access_key\": \"my_key_secret\"	\
		  }"
}

#####################################
function conjur_whoami {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CYBERARK_CCLOUD_API}/whoami"
}

#####################################
function conjur_resources {
  $util_defaults
  $CURL 						\
	-X GET						\
	-H "$authHeader" 				\
	"$CYBERARK_CCLOUD_API/resources/conjur" | jq
}

#####################################
function conjur_list {
  $util_defaults
  resources=$(conjur_resources)
  echo "${resources}" | jq -r .[].id
}

#####################################
function conjur_get_variable {
  $util_defaults
  varName=$1
  var=$(urlify $varName)
  value=$($CURL							\
	  -X GET 						\
	  $CYBERARK_CCLOUD_API/secrets/conjur/variable/$var	\
          -H "Content-Type: application/json"			\
	  -H "$authHeader")
  echo -n "${value}"
}

#####################################
function conjur_set_variable {
  $util_defaults
  variable_name=$1
  variable_value="$2"
  $CURL					\
  	-H "$authHeader"		\
	--data "$variable_value"	\
	"$CYBERARK_CCLOUD_API/secrets/conjur/variable/$variable_name"
}

#####################################
function conjur_append_policy {
  $util_defaults
  policy_branch=$1
  policy_name=$2
  response=$($CURL			\
	-X POST				\
  	-H "$authHeader"		\
	-d "$(< $policy_name)"		\
	$CYBERARK_CCLOUD_API/policies/conjur/policy/$policy_branch)
  echo "$response"
}

#####################################
function conjur_update_policy {
  $util_defaults
  policy_branch=$1
  policy_name=$2
  response=$($CURL				\
	-X PATCH				\
  	-H "$authHeader"			\
	-d "$(< $policy_name)"			\
	$CYBERARK_CCLOUD_API/policies/conjur/policy/$policy_branch)
  echo "$response"
}

#####################################
function conjur_authn_enable {
  $util_defaults
  authnType=$1; shift
  serviceId=$1; shift
  response=$($CURL						\
  	-X PATCH 						\
  	-H "$authHeader" 					\
	-d "enabled=true"					\
	"${CYBERARK_CCLOUD_API}/${authnType}/${serviceId}/conjur")
  echo "$response"
}

#####################################
function conjur_authn_status {
  $util_defaults
  authnType=$1; shift
  serviceId=$1; shift
  response=$($CURL						\
        -X GET							\
        -H "$authHeader"                                        \
        -d "enabled=true"                                       \
        "${CYBERARK_CCLOUD_API}/${authnType}/${serviceId}/conjur/status")
  echo "$response"
}

#####################################
function conjur_rotate_api_key {
	local kind=$1; shift		# user or host
	local id=$1; shift
	$util_defaults
	api_key=$(curl $CONJUR_VERBOSE -X PUT -sk 	\
		-H "$authHeader"				\
		"$CYBERARK_CCLOUD_API/authn/${CONJUR_ACCOUNT}/api_key?role=conjur:${kind}:${id}")
	echo $api_key
}

#####################################
function conjur_set_user_password() {
	local username=$1; shift
	local current_password="$1"; shift	# can be API key
	local new_password="$1"; shift
	$util_defaults
	curl $CONJUR_VERBOSE --fail -s -k 				\
		--user "$username:$current_password"			\
		$CYBERARK_CCLOUD_API/authn/conjur/login
	curl $CONJUR_VERBOSE -X PUT -s -k				\
		--data "$new_password"					\
		--user $username:"$current_password"			\
		"$CYBERARK_CCLOUD_API/authn/${CONJUR_ACCOUNT}/password"
}

#####################################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: encoded string on stdout
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        str=$(echo $str | sed 's=+=%2B=g')
        str=$(echo $str | sed 's=&=%26=g')
        str=$(echo $str | sed 's=@=%40=g')
        echo $str
}

#####################################
# verifies jq installed & required environment variables are set
function checkDependencies() {
  all_env_set=true
  if [[ "$(which jq)" == "" ]]; then
    echo
    echo "The JSON query utility jq is required. Please install jq."
    all_env_set=false
  fi
  if [[ "$CYBERARK_IDENTITY_URL" == "" ]]; then
    echo
    echo "  CYBERARK_IDENTITY_URL must be set."
    all_env_set=false
  fi
  if [[ "$CYBERARK_CCLOUD_API" == "" ]]; then
    echo
    echo "  CYBERARK_CCLOUD_API must be set - e.g. 'https://my-secrets.secretsmgr.cyberark.cloud/api'"
    all_env_set=false
  fi
  if [[ "$CYBERARK_ADMIN_USER" == "" ]]; then
    echo
    echo "  CYBERARK_ADMIN_USER must be set - e.g. foo_bar@cyberark.cloud.7890"
    echo "    This MUST be a Service User and Oauth confidential client."
    echo "    This script will not work for human user identities."
    all_env_set=false
  fi
  if [[ "$CYBERARK_ADMIN_PWD" == "" ]]; then
    echo
    echo "  CYBERARK_ADMIN_PWD must be set to the $CYBERARK_ADMIN_USER password."
    all_env_set=false
  fi
  if ! $all_env_set; then
    echo
    exit -1
  fi
}

main "$@"
