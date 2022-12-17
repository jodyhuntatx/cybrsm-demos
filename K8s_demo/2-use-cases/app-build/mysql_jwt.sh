#!/bin/bash

export JWT=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
export AUTHN_JWT_ENDPOINT=$CONJUR_APPLIANCE_URL/authn-jwt/$JWT_SERVICE_ID/$CONJUR_ACCOUNT/authenticate

main() {
  AUTHN_TOKEN=$(curl -sk "$AUTHN_JWT_ENDPOINT"			\
	-H 'Content-Type: application/x-www-form-urlencoded'	\
	-H "Accept-Encoding: base64" 				\
	--data-urlencode "jwt=$JWT")

  DB_HOSTNAME_ID=$(urlify "$DB_HOSTNAME_ID")
  DB_NAME_ID=$(urlify "$DB_NAME_ID")
  DB_UNAME_ID=$(urlify "$DB_UNAME_ID")
  DB_PWD_ID=$(urlify "$DB_PWD_ID")

  DB_HOSTNAME=$(curl -s -k \
	--request GET \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$AUTHN_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$DB_HOSTNAME_ID)

  DB_NAME=$(curl -s -k \
	--request GET \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$AUTHN_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$DB_NAME_ID)

  DB_UNAME=$(curl -s -k \
	--request GET \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$AUTHN_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$DB_UNAME_ID)

  DB_PWD=$(curl -s -k \
	--request GET \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$AUTHN_TOKEN\"" \
        $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$DB_PWD_ID)

  echo
  echo "The retrieved values are:"
  echo "  DB_HOSTNAME: $DB_HOSTNAME"
  echo "  DB_NAME: $DB_NAME"
  echo "  DB_UNAME: $DB_UNAME"
  echo "  DB_PWD: $DB_PWD"
  echo

  set -x
  mysql -h $DB_HOSTNAME -u $DB_UNAME --password=$DB_PWD $DB_NAME
}

################
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

exit
