#!/bin/bash
		# magic that sets CONJUR_HOME to parent directory of this script
CONJUR_HOME="$(ls $0 | rev | cut -d "/" -f2- | rev)/.."
source $CONJUR_HOME/config/conjur.config

# Authenticates as admin user and lists all resources

AUTHN_TOKEN=""

################  MAIN   ################
main() {
  authn_user   # authenticate user
  if [[ "$AUTHN_TOKEN" == "" ]]; then
    echo "Authentication failed..."
    exit -1
  fi

  curl -sk \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$AUTHN_TOKEN\"" \
     $CONJUR_APPLIANCE_URL/resources/$CONJUR_ACCOUNT | jq .[].id
}

##################
# AUTHN USER - sets AUTHN_TOKEN globally
# - no arguments
authn_user() {
  if [ -z ${CONJUR_ADMIN_USERNAME+x} ]; then
    >&2 echo
    >&2 echo -n Enter admin user name:
    read admin_uname
    >$2 echo -n Enter the admin password \(it will not be echoed\):
    read -s admin_pwd
    export CONJUR_ADMIN_USERNAME=$admin_uname
    export CONJUR_ADMIN_PASSWORD=$admin_pwd
  fi

  # Login user, authenticate and set authn token
  local api_key=$(curl \
                    -sk \
                    --user $CONJUR_ADMIN_USERNAME:$CONJUR_ADMIN_PASSWORD \
                    $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/login)

  local response=$(curl -sk \
                     --data $api_key \
                     $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/$CONJUR_ADMIN_USERNAME/authenticate)
  AUTHN_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')
}

################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: URLIFIED - global variable containing encoded string
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        str=$(echo $str | sed 's=+=%2B=g')
        str=$(echo $str | sed 's=&=%26=g')
        str=$(echo $str | sed 's=@=%40=g')
        URLIFIED=$str
}

main "$@"
