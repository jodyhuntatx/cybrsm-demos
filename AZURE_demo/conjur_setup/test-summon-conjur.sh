#!/bin/bash

export CONJUR_APPLIANCE_URL=https://ConjurMaster2.northcentralus.cloudapp.azure.com
export CONJUR_AUTHN_AZ_ID=sub1
export CONJUR_ACCOUNT=dev
export DAP_HOST_ID=host/apps/rgrp1-sid1
# CLIENT_ID must be empty for system-assigned identity
export CLIENT_ID=""

./summon-conjur-az.sh $@
