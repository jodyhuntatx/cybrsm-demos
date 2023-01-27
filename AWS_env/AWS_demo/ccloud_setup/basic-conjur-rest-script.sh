#!/bin/bash

source ./ccloudvars.sh

set -x
main() {
  AUTH_TOKEN=$(curl -vk \
        -X POST \
        https://$IDENTITY_TENANT_ID.id.cyberark.cloud/oauth2/platformtoken \
        --header "Content-Type: application/x-www-form-urlencoded"      \
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CONJUR_ADMIN_USER"		\
        --data-urlencode "client_secret"="$CONJUR_ADMIN_PWD"		\
	| jq -r .access_token)

exit

  VAR_ID=$(urlify "$VAR_ID")
  VAR_VALUE=$(curl -sk \
	--request GET \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$AUTHN_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$VAR_ID)

  echo
  echo "The retrieved value is: $VAR_VALUE"
  echo
}

################
# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# returns URL-encoded string
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        echo $str
}

main "$@"

exit
