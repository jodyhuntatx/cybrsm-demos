#!/bin/bash

source ./ccloud-vars.sh

# use 'curl -v' and 'set -x' for verbose debugging
export CURL="curl -s"
util_defaults="set -u"

TENANT_NAME=cybr-secrets

jwToken=$($CURL \
        -X POST \
        https://$IDENTITY_TENANT_ID.id.cyberark.cloud/oauth2/platformtoken \
        -H "Content-Type: application/x-www-form-urlencoded"            \
        --data-urlencode "grant_type"="client_credentials"              \
        --data-urlencode "client_id"="$CONJUR_ADMIN_USER"               \
        --data-urlencode "client_secret"="$CONJUR_ADMIN_PWD"            \
        | jq -r .access_token)

CURL -X GET \
	https://$TENANT_NAME-secrets_hub.cyberark.cloud/api/secret-stores \
        --header "Content-Type: application/json"               	\
        --header "Authorization: $jwToken"
