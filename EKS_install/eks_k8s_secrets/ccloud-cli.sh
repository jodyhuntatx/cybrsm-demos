#!/bin/bash

####################################################
# ccloud-cli.sh - a bash script CLI for Conjur Cloud
####################################################

# With Conjur Cloud, the server cert and -k flag are not required.
# use 'curl -v' and 'set -x' for verbose debugging 
export CURL="curl -s"
util_defaults="set -u"

showUsage() {
  echo "Usage:"
  echo "      $0 [ whoami | resources | list | info | health | audit ]"
  echo "      $0 [ get <var-name> ]"
  echo "      $0 [ set <var-name> <var-value> ]"
  echo "      $0 [ append <policy-branch> <policy-file-name> ]"
  echo "      $0 [ update <policy-branch> <policy-file-name> ]"
  echo "      $0 [ enable <authn-type> <service-id> ]"
  echo "      $0 [ status <authn-type> <service-id> ]"
  exit -1
}

main() {
  checkEnvVars

  case $1 in
    whoami | resources | list | info | health | audit)
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
    *)
	showUsage
	;;
  esac

  conjur_authenticate	# sets global variable authHeader

  case $command in
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
    info)
	conjur_info
	;; 
    health)
	conjur_health
	;; 
    audit)
	conjur_audit 
	;;
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
        https://$IDENTITY_TENANT_ID.id.cyberark.cloud/oauth2/platformtoken \
        -H "Content-Type: application/x-www-form-urlencoded"      	\
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CONJUR_ADMIN_USER"               \
        --data-urlencode "client_secret"="$CONJUR_ADMIN_PWD"		\
	| jq -r .access_token)
  authToken=$($CURL	\
        -X POST		\
	$CONJUR_CLOUD_URL/authn-oidc/cyberark/conjur/authenticate 	\
	-H "Content-Type: application/x-www-form-urlencoded"		\
	-H "Accept-Encoding: base64"					\
	--data-urlencode "id_token=$jwToken")
  authHeader="Authorization: Token token=\"$authToken\""
}

#####################################
function conjur_whoami {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CONJUR_CLOUD_URL}/whoami"
}

#####################################
function conjur_resources {
  $util_defaults
  $CURL 						\
	-X GET						\
	-H "$authHeader" 				\
	"$CONJUR_CLOUD_URL/resources/conjur" | jq
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
	  $CONJUR_CLOUD_URL/secrets/conjur/variable/$var	\
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
	"$CONJUR_CLOUD_URL/secrets/conjur/variable/$variable_name"
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
	$CONJUR_CLOUD_URL/policies/conjur/policy/$policy_branch)
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
	$CONJUR_CLOUD_URL/policies/conjur/policy/$policy_branch)
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
	"${CONJUR_CLOUD_URL}/${authnType}/${serviceId}/conjur")
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
        "${CONJUR_CLOUD_URL}/${authnType}/${serviceId}/conjur/status")
  echo "$response"
}

#####################################
# prob does not work for users - now managed in Identity
# not tested as of 1/27/23
function conjur_rotate_api_key {
	local kind=$1; shift		# user or host
	local id=$1; shift
	$util_defaults
	api_key=$($CURL						\
		-X PUT						\
		-H "$authHeader"				\
		"$CONJUR_CLOUD_URL/authn/${CONJUR_ACCOUNT}/api_key?role=conjur:${kind}:${id}")
	echo $api_key
}

#####################################
# prob does not work cuz users are managed in Identity
# not tested as of 1/27/23
function conjur_set_user_password() {
	local username=$1; shift
	local current_password="$1"; shift	# can be API key
	local new_password="$1"; shift
	$util_defaults
	$CURL								\
		-X PUT							\
		--user "$username:$current_password"			\
		$CONJUR_CLOUD_URL/authn/conjur/login
	$CURL								\
		-X PUT							\
		--data "$new_password"					\
		--user $username:"$current_password"			\
		"$CONJUR_CLOUD_URL/authn/${CONJUR_ACCOUNT}/password"
}

#####################################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: encoded string on stdout
function urlify() {
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
# verifies required environment variables are set
function checkEnvVars() {
  all_env_set=true
  if [[ "$IDENTITY_TENANT_ID" == "" ]]; then
    echo

    echo "  IDENTITY_TENANT_ID must be set - e.g. 'xyz1234'"
    all_env_set=false
  fi
  if [[ "$CONJUR_CLOUD_URL" == "" ]]; then
    echo
    echo "  CONJUR_CLOUD_URL must be set - e.g. 'https://my-secrets.secretsmgr.cyberark.cloud/api'"
    echo "    (and dont forget the /api)"
    all_env_set=false
  fi
  if [[ "$CONJUR_ADMIN_USER" == "" ]]; then
    echo
    echo "  CONJUR_ADMIN_USER must be set - e.g. foo_bar@cyberark.cloud.7890"
    echo "    This MUST be a Service User and Oauth confidential client."
    echo "    This script will not work for human user identities."
    all_env_set=false
  fi
  if [[ "$CONJUR_ADMIN_PWD" == "" ]]; then
    echo
    echo "  CONJUR_ADMIN_PWD must be set to the CONJUR_ADMIN_USER password."
    all_env_set=false
  fi
  if ! $all_env_set; then
    echo
    exit -1
  fi
}

main "$@"

#####################################
# not implented in Conjur Cloud?
function conjur_info {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CONJUR_CLOUD_URL}/info"
}

#####################################
# not implented in Conjur Cloud?
function conjur_health {
  $util_defaults
  $CURL 				\
	-X GET				\
	-H "$authHeader"		\
	"${CONJUR_CLOUD_URL}/health"
}

#####################################
# not implented in Conjur Cloud?
function conjur_audit {
  $util_defaults
  response=$($CURL			\
	  -H "$authHeader"		\
	"${CONJUR_CLOUD_URL}/audit")
  echo "$response"
}

