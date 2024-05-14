#!/bin/bash

export CURL="curl -sk"

# debugging
util_defaults="set -u"
CONJUR_VERBOSE=${CONJUR_VERBOSE:-""}		# sets CONJUR_VERBOSE to "" if undefined

ISSUER_TTL=3000
ISSUER_KEY_ID=$(cat ~/.aws/jhunt_credentials | grep aws_access | cut -d= -f2)
ISSUER_SECRET_KEY=$(cat ~/.aws/jhunt_credentials | grep aws_secret | cut -d= -f2)

#CONJUR_AUTHN_API_KEY

showUsage() {
  echo "Usage:"
  echo "  $0 issuer_list"
  echo "  $0 issuer_create <issuer-id>"
  echo "  $0 issuer_get <issuer-id>"
  echo "  $0 issuer_delete <issuer-id>"
  echo "  $0 variable_get <variable-id>"
  exit -1
}

main() {
  case $1 in
    issuer_list)
	command=$1
	;;
    issuer_create | issuer_get | issuer_delete)
	if [[ $# != 2 ]]; then
	  showUsage
	fi
	command=$1
	issuerId=$2
	;;
    variable_get)
	if [[ $# != 2 ]]; then
	  showUsage
	fi
	command=$1
	variableId=$2
	;;
    *)
	showUsage
	;;
  esac

  AUTH_TOKEN=$(./ccloud-cli.sh auth_token_get)

  $command
}

#################################
function issuer_list() {
  $CURL -X GET 				 		\
	-H "Authorization: Token token=\"$AUTH_TOKEN\""	\
	$CYBERARK_CCLOUD_API/issuers/conjur		\
  | jq .
}

#################################
function issuer_create() {
  $CURL -X POST 				 	\
	-H "Authorization: Token token=\"$AUTH_TOKEN\""	\
	-H "Content-Type: application/json"		\
	$CYBERARK_CCLOUD_API/issuers/conjur		\
	--data "{
		\"id\": \"$issuerId\",
		\"max_ttl\": $ISSUER_TTL,
		\"type\": \"aws\",
		\"data\": {
		  \"access_key_id\": \"$ISSUER_KEY_ID\",
		  \"secret_access_key\": \"$ISSUER_SECRET_KEY\"
	  	}
	}"						\
  | jq .
}

#################################
function issuer_get() {
  $CURL -X GET						\
	-H "Authorization: Token token=\"$AUTH_TOKEN\""	\
	$CYBERARK_CCLOUD_API/issuers/conjur/$issuerId	\
  | jq .
}

#################################
function issuer_delete() {
  $CURL -X DELETE					\
	-H "Authorization: Token token=\"$AUTH_TOKEN\""	\
	$CYBERARK_CCLOUD_API/issuers/conjur/$issuerId
}

#####################################
function variable_get(){
  $util_defaults
  
  RAW_TOKEN=$(curl -sk \
                 --data $CONJUR_AUTHN_API_KEY   \
                 $CYBERARK_CCLOUD_API/authn/conjur/jody-ephemeral-test/authenticate)
  AUTHN_TOKEN=$(echo -n $RAW_TOKEN | base64 | tr -d '\r\n')
  value=$($CURL                                                 	\
          -X GET                                                	\
          $CYBERARK_CCLOUD_API/secrets/conjur/variable/$variableId	\
	  -H "Authorization: Token token=\"$AUTH_TOKEN\"")
  echo -n "${value}"
}

main "$@"

