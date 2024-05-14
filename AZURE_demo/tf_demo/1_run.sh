#!/bin/bash

set -eou pipefail

export CONJUR_APPLIANCE_URL=https://ConjurMaster2.northcentralus.cloudapp.azure.com
export CONJUR_AUTHN_AZ_ID=jdemo
export CONJUR_ACCOUNT=dev

# Managed identity 1
TF_ID_1_HOST=host/tf-build-ids/tf-id-1
TF_ID_1_CLIENT_ID=e93e05b4-dfc0-47c6-be62-6494d08f2301

# Managed identity 2
TF_ID_2_HOST=host/tf-build-ids/tf-id-2
TF_ID_2_CLIENT_ID=dd5ef44a-595d-4586-ae3c-b8772d27577c

# Managed identity 3
TF_ID_3_HOST=host/tf-build-ids/tf-id-3
TF_ID_3_CLIENT_ID=""

###########################################3
export DAP_HOST_ID=$TF_ID_2_HOST
# CLIENT_ID must be empty for system-assigned identity
export CLIENT_ID=$TF_ID_2_CLIENT_ID

#export DEBUG=true
#echo $(./summon-conjur-az.sh DemoVault/CICD/CICD_Secrets/Database-MSSql-JodyDBUser/password)
set -x
summon -p ./summon-conjur-az.sh terraform apply
