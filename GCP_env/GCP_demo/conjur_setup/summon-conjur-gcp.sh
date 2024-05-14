#!/bin/bash
set -ou pipefail
main() {
  if [[ $# != 1 ]]; then
    echo "Usage: $0 <conjur-variable-name>"
    exit -1
  fi
  VAR_NAME=$1
  GCP_TOKEN=$(get_gcp_token $CONJUR_HOST_ID)
  CONJUR_TOKEN=$(authenticate_conjur_host $GCP_TOKEN)
  VAR_VALUE=$(get_variable_value $CONJUR_TOKEN $VAR_NAME)
  echo $VAR_VALUE
}

################################
get_gcp_token() {
  local conjur_host_id=$1; shift
  local gcp_token=$(curl -s -G -H "Metadata-Flavor: Google" \
    --data-urlencode "audience=conjur/$CONJUR_ACCOUNT/host/$conjur_host_id" \
    --data-urlencode "format=full" \
    "http://metadata/computeMetadata/v1/instance/service-accounts/default/identity")
  echo $gcp_token
}

################################
authenticate_conjur_host() {
  local gcp_token=$1; shift
  local conjur_token=$(curl -sk https://$CONJUR_LEADER_HOSTNAME/authn-gcp/$CONJUR_ACCOUNT/authenticate \
  -H Accept-Encoding: base64				\
  -H Content-Type: application/x-www-form-urlencoded	\
  --data-urlencode "jwt=$gcp_token")
  enc_token=$(echo $conjur_token | base64 | tr -d '\r\n')
  echo $enc_token
}

################################
get_variable_value() {
  local conjur_token=$1; shift
  local var_name=$1; shift
  enc_var_name=$(urlify $var_name)
  var_value=$(curl -sk \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$conjur_token\"" \
        $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$enc_var_name)
  echo $var_value
}
	
################################
# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# out: URLIFIED - converted string in global variable
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        echo $str
}
 
main "$@"
