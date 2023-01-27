#!/bin/bash

# get_conjur_secret.sh
#
# - Authenticates a CyberArk Identity Service User with their uname/pwd to get its JWT.
# - Authenticates to Conjur Cloud with the JWT to get the Conjur auth token
# - Uses the token to retrieve a secret.

source ./ccloudvars.sh

varName=data/vault/gitlab-cybrlab-conjur-cloud/system-user/password

main() {
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
	$CONJUR_URL/authn-oidc/cyberark/conjur/authenticate 		\
	-H "Content-Type: application/x-www-form-urlencoded"		\
	-H "Accept-Encoding: base64"					\
	--data-urlencode "id_token=$jwToken" )

  var=$(urlify $varName)
  $CURL \
        -X GET 						\
	$CONJUR_URL/secrets/conjur/variable/$var	\
        -H "Content-Type: application/json"		\
        -H "Authorization: Token token=\"$authToken\""
}

################
# URLIFY - urlencodes input string
# in: $1 - string to convert
# out: urlencoded string
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        echo $str
}

main "$@"
