#!/bin/bash

if [[ $# != 3 ]]; then
  echo "Usage: $0 <container-name> <hostname> <apikey>"
  exit -1
fi
CONTAINER_NAME=$1

echo "- !host $MYSQL_APP_IDENTITY" > tmp
cybr conjur logon-non-interactive
cybr conjur append-policy -b root -f tmp
rm tmp
MYSQL_APP_API_KEY=$(cybr conjur rotate-api-key -l host/$MYSQL_APP_IDENTITY)

# create configuration and identity files (AKA conjurize the host)
echo "Generating identity file..."
cat <<IDENTITY_EOF | tee conjur.identity
machine $CONJUR_APPLIANCE_URL/authn
  login host/$MYSQL_APP_IDENTITY
  password $MYSQL_APP_API_KEY
IDENTITY_EOF

echo
echo "Generating host configuration file..."
cat <<CONF_EOF | tee conjur.conf
---
appliance_url: $CONJUR_APPLIANCE_URL
account: $CONJUR_ACCOUNT
netrc_path: "/etc/conjur.identity"
cert_file: "/etc/conjur-$CONJUR_ACCOUNT.pem"
CONF_EOF

$DOCKER cp $CONJUR_CERT_FILE $MYSQL_CLIENT:/etc/conjur-$CONJUR_ACCOUNT.pem
$DOCKER cp ./conjur.conf $MYSQL_CLIENT:/etc
$DOCKER cp ./conjur.identity $MYSQL_CLIENT:/etc
$DOCKER exec $MYSQL_CLIENT chmod 400 /etc/conjur.identity
rm ./conjur*
