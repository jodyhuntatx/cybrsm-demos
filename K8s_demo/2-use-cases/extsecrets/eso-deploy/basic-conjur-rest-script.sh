#!/bin/bash
export CONJUR_APPLIANCE_URL=https://cybr-secrets.secretsmgr.cyberark.cloud/api
export CONJUR_ACCOUNT=conjur

if [[ "$CONJUR_APPLIANCE_URL" == "" ]]; then
  echo "Set env var CONJUR_APPLIANCE_URL."
  exit -1
fi
if [[ "$CONJUR_ACCOUNT" == "" ]]; then
  echo "Set env var CONJUR_ACCOUNT."
  exit -1
fi

main() {
  if [[ $# != 3 ]]; then
    echo "Usage: $0 <conjur-host-name> <conjur-api-key> <variable-name-to-retrieve-value>"
    echo "Example:"
    echo "   $0 host/demo/app 38389d9w920920038393009d893 secrets/database-password"
    exit -1
  fi
  CONJUR_AUTHN_LOGIN=$1
  CONJUR_AUTHN_API_KEY=$2
  VAR_ID=$3

  URLENC_HOST=$(urlify "$CONJUR_AUTHN_LOGIN")
  RAW_TOKEN=$(curl -sk \
                 --data $CONJUR_AUTHN_API_KEY	\
                 $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/$URLENC_HOST/authenticate)
  AUTHN_TOKEN=$(echo -n $RAW_TOKEN | base64 | tr -d '\r\n')

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
