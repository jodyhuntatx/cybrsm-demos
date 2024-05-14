#!/bin/bash
#
# Authenticates using Azure access token and gets value of a specified variable
#

# URL and ACCOUNT are taken from build vars in library
export CONJUR_APPLIANCE_URL=https://ConjurMaster2.northcentralus.cloudapp.azure.com
export CONJUR_ACCOUNT=dev
export CONJUR_CERT_FILE=./conjur-dev.pem
export AUTHN_AZ_ID=sub1

################  MAIN   ################
# Takes 2 arguments:
#   $1 - host/<dap-host-identity-from-policy>
#   $2 - name of variable to value to return
#
main() {
  if [[ $# -ne 2 ]] ; then
    printf "\nUsage: %s <host-identity> <variable-name>\n" $0
    exit -1
  fi
  local CONJUR_AUTHN_LOGIN=$1
  local variable_name=$2
				# authenticate, get ACCESS_TOKEN
  ACCESS_TOKEN=$(authn_host $CONJUR_AUTHN_LOGIN)
  if [[ "$ACCESS_TOKEN" == "" ]]; then
    echo "Authentication failed..."
    exit -1
  fi

  local encoded_var_name=$(urlify "$variable_name")
  curl -s \
	--cacert $CONJUR_CERT_FILE \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$ACCESS_TOKEN\"" \
     $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$encoded_var_name
}

##################
# AUTHN HOST
#  $1 - host identity
#
authn_host() {
  local host_id=$1; shift

  # get Azure access token for managed identity from instance metadata service (imds)
  imds_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F"
  azure_access_token=$(curl -s			\
		         "$imds_endpoint"	\
		         -H Metadata:true	\
   			| jq -r '.access_token')

  if [[ $azure_access_token == null ]]; then
    echo "Error retrieving Azure access token"
#  else
#    echo "Azure token: $azure_access_token"
  fi

  local encoded_host_id=$(urlify "host/$host_id")
  authn_azure_response=$(curl -s -X POST \
	-H "Content-Type: application/x-www-form-urlencoded" \
	--cacert $CONJUR_CERT_FILE \
	--data "jwt=$azure_access_token" \
	$CONJUR_APPLIANCE_URL/authn-azure/$AUTHN_AZ_ID/$CONJUR_ACCOUNT/${encoded_host_id}/authenticate)
  conjur_access_token=$(echo -n $authn_azure_response| base64 | tr -d '\r\n')
  echo "$conjur_access_token"
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
