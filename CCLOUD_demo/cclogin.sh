#!/bin/bash

CURL="curl -s"
CONJUR_URL=https://cybr-secrets.secretsmgr.cyberark.cloud/api
TENANT_DOMAIN=cyberark.cloud.3357
ADMIN_USER=jody_hunt@$TENANT_DOMAIN
ADMIN_PWD=$(keyring get cybrid admpwd)

conjur init -u $CONJUR_URL
conjur -d login -i $ADMIN_USER -p $ADMIN_PWD 
