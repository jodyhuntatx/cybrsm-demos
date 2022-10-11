#!/bin/bash

source ./conjur_utils.sh

echo -n "Enter the Cnnjur URL: "
read CONJUR_APPLIANCE_URL
export CONJUR_APPLIANCE_URL
echo -n "Enter the Cnnjur Account: "
read CONJUR_ACCOUNT
export CONJUR_ACCOUNT
echo -n "Enter the Cnnjur admin name: "
read CONJUR_AUTHN_LOGIN
>&2 echo -n Enter the admin password \(it will not be echoed\):
read -s CONJUR_AUTHN_API_KEY
echo
echo -n "Enter application host name to use: " 
read CONJUR_HOSTNAME
echo -n "Enter variable name to use: " 
read VARIABLE_NAME
echo -n "Enter value to set variable to: " 
read VARIABLE_VALUE

# instantiate and load policy
cat ./basic-policy.template					\
  | sed -e "s#{{ CONJUR_HOSTNAME }}#$CONJUR_HOSTNAME#g"		\
  | sed -e "s#{{ VARIABLE_NAME }}#$VARIABLE_NAME#g"		\
  > basic-policy.yml
conjur_update_policy root basic-policy.yml > /dev/null			# see conjur_utils.sh

# set value of variable
echo "Setting variable: $VARIABLE_NAME with value $VARIABLE_VALUE..." 
conjur_set_variable $VARIABLE_NAME $VARIABLE_VALUE			# see conjur_utils.sh

# generate api key for host authentication
NEW_API_KEY=$(conjur_rotate_api_key host $CONJUR_HOSTNAME)		# see conjur_utils.sh

echo
echo "Demo env vars:"
echo "  Conjur URL: $CONJUR_APPLIANCE_URL"
echo "  Conjur Account: $CONJUR_ACCOUNT"
echo
echo "Demo command-line vars:"
echo "  Hostname: host/$CONJUR_HOSTNAME"
echo "  API key: $NEW_API_KEY"
echo "  Variable name: $VARIABLE_NAME"
echo

./basic-conjur-rest-script.sh host/$CONJUR_HOSTNAME $NEW_API_KEY $VARIABLE_NAME
