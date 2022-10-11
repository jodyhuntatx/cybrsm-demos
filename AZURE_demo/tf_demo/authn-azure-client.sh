#!/bin/bash  -x
set -euo pipefail

# Summon provider using Azure managed identity authentication

# Uses the following non-secret env vars:
#  CONJUR_APPLIANCE_URL - location & port of DAP service
#  CONJUR_AUTHN_AZ_ID - DAP authn-azure ID for authenticaiton in this Azure tenant
#  CONJUR_ACCOUNT - default DAP namespace
#  CLIENT_ID - Azure client id, if set -> User-assigned ID, if not -> System assigned
#  DAP_HOST_ID - name of DAP host to use to retrieve secret

CLIENT_ID=${CLIENT_ID:-""}
DEBUG=${DEBUG:-false}

# set Azure IMDS endpoint for either user-assigned and system-assigned identities
if [[ "$CLIENT_ID" != "" ]]; then
    imds_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2020-09-01&client_id=${CLIENT_ID}&resource=https%3A%2F%2Fmanagement.azure.com%2F"
  else
    imds_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2020-09-01&resource=https%3A%2F%2Fmanagement.azure.com%2F"
fi

################################
function main() {
  if [[ $# != 1 ]]; then
    echo "Usage: $0 <secret-name>"
    exit -1
  fi
  local secret_name=$1

  if $DEBUG; then
    echo "CONJUR_APPLIANCE_URL:" $CONJUR_APPLIANCE_URL
    echo "CONJUR_AUTHN_AZ_ID:" $CONJUR_AUTHN_AZ_ID
    echo "CONJUR_ACCOUNT:" $CONJUR_ACCOUNT
    echo "CLIENT_ID:" $CLIENT_ID
    echo "DAP_HOST_ID:" $DAP_HOST_ID
    echo "imds_endpoint:" $imds_endpoint
  fi

  azure_token=$(curl -s "$imds_endpoint" -H Metadata:true | jq -r '.access_token')
  if [[ $azure_token == null ]]; then
    echo "Error retrieving Azure access token"
    exit -1
  fi

  encoded_role=$(urlify $DAP_HOST_ID)
  conjur_jwt=$(curl -sk -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data "jwt=$azure_token" \
      $CONJUR_APPLIANCE_URL/authn-azure/$CONJUR_AUTHN_AZ_ID/$CONJUR_ACCOUNT/${encoded_role}/authenticate)

  if [[ "$conjur_jwt" != "" ]]; then
    conjur_access_token=$(echo -n "$conjur_jwt" | base64 | tr -d '\r\n')
  else
    echo "Error authenticating to Conjur authn-az endpoint:" $CONJUR_AUTHN_AZ_ID
    exit -1
  fi

  encoded_name=$(urlify $secret_name)
  echo $(curl -sk -H "Authorization: Token token=\"${conjur_access_token}\"" \
      $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/${encoded_name})
}

################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: encoded string
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

main "$@"
