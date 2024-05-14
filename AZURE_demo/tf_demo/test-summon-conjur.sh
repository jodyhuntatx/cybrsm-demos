#!/bin/bash

export CONJUR_APPLIANCE_URL=https://ConjurMaster2.northcentralus.cloudapp.azure.com
export CONJUR_AUTHN_AZ_ID=sub1
export CONJUR_ACCOUNT=dev
export DAP_HOST_ID=host/apps/rgrp1-uid1
# CLIENT_ID must be empty for system-assigned identity
export CLIENT_ID=b3af4cc0-2f36-4fa6-a58b-43db541352b6
export DEBUG=true
#./summon-conjur-az.sh DemoVault/CICD/CICD_Secrets/Database-MSSql-JodyDBUser/password
summon terraform apply
