#!/bin/bash -x
set -euo pipefail

#test-var-sub1-rgrp1
#test-var-sub1-rgrp1-sid1
#test-var-sub1-rgrp1-uid1
#test-var-sub1-rgrp2-uid1
#test-var-sub2-rgrp1-uid1

source ./azure.config

function main() {
   echo "###############################"
   echo "Happy paths from host1 - all should succeed."
   rgroup_identity "sub1-apps/rgrp1" "test-var-sub1-rgrp1"
   system_assigned_identity "sub1-apps/rgrp1-sid1" "test-var-sub1-rgrp1-sid1"
   user_assigned_identity "sub1-apps/rgrp1-uid1" "b3af4cc0-2f36-4fa6-a58b-43db541352b6" "test-var-sub1-rgrp1-uid1"
   user_assigned_identity "sub1-apps/rgrp2-uid1" "b7d5c172-6d43-4575-827d-5cf31ac4011a" "test-var-sub1-rgrp2-uid1"

   echo
   echo "###############################"
   echo "Unhappy paths from host1 - all should fail."
   echo
   echo "rgrp1 identity tries to retrieve variable w/ no access"
   rgroup_identity "sub1-apps/rgrp1" "test-var-sub1-rgrp1-sid1"
   echo
   echo "sid1 identity tries to retrieve variable w/ no access"
   system_assigned_identity "sub1-apps/rgrp1-sid1" "test-var-sub1-rgrp1"
   echo
   echo "uid1 identity tries to retrieve variable w/ no access"
   user_assigned_identity "sub1-apps/rgrp1-uid1" "b3af4cc0-2f36-4fa6-a58b-43db541352b6" "test-var-sub1-rgrp2-uid1"
   echo
   echo "uid2 identity tries to retrieve variable w/ no access"
   user_assigned_identity "sub1-apps/rgrp2-uid1" "b7d5c172-6d43-4575-827d-5cf31ac4011a" "test-var-sub1-rgrp1-uid1"
   echo
}

################################
function user_assigned_identity() {
    local uid_hostname=$1; shift
    local uid_client_id=$1; shift
    local uid_secret_name=$1; shift

    echo
    echo "User-assigned identity: $uid_hostname"
    echo "UA client_id: $uid_client_id"
    echo "Secret to retrieve: $uid_secret_name"

    user_assigned_identity_token_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2020-09-01&client_id=${uid_client_id}&resource=https%3A%2F%2Fmanagement.azure.com%2F"

    getConjurTokenWithAzureIdentity $user_assigned_identity_token_endpoint $uid_hostname
    getConjurSecret $uid_secret_name
}

################################
function system_assigned_identity() {
    local sid_hostname=$1; shift
    local sid_secret_name=$1; shift

    echo
    echo "System-assigned identity: $sid_hostname"
    echo "Secret to retrieve: $sid_secret_name"

    system_assigned_identity_token_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F"

    getConjurTokenWithAzureIdentity $system_assigned_identity_token_endpoint $sid_hostname
    getConjurSecret $sid_secret_name
}

################################
function rgroup_identity() {
    local rgrpid_hostname=$1; shift
    local rgrpid_secret_name=$1; shift

    echo
    echo "Resource group identity: $rgrpid_hostname"
    echo "Secret to retrieve: $rgrpid_secret_name"

    rgroup_identity_token_endpoint="http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F"

    getConjurTokenWithAzureIdentity $rgroup_identity_token_endpoint $rgrpid_hostname
    getConjurSecret $rgrpid_secret_name
}

################################
function getConjurTokenWithAzureIdentity() {
    local azure_token_endpoint="$1"; shift
    local conjur_role="$1"; shift

    azure_access_token=$(getAzureAccessToken $azure_token_endpoint)
    if [[ $azure_access_token == null ]]; then
      echo "Error retrieving Azure access token"
#    else
#      echo "Azure token: $azure_access_token"
    fi
    echo "Azure token: $azure_access_token"

    getConjurToken $azure_access_token $conjur_role
}

################################
function getAzureAccessToken(){
    local az_endpoint=$1; shift

    azure_token=$(curl -s		 \
		         "$az_endpoint" \
		         -H Metadata:true	 \
   			| jq -r '.access_token')
    echo $azure_token
}

################################
function getConjurToken() {
    local az_token=$1; shift
    local conjur_role=$1; shift
    AUTHN_AZ_ID=sub1

    encoded_role=$(urlify host/$conjur_role)
    authn_azure_response=$(curl -sk -X POST \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data "jwt=$az_token" \
      $CONJUR_APPLIANCE_URL/authn-azure/$AUTHN_AZ_ID/$CONJUR_ACCOUNT/${encoded_role}/authenticate)

    if [[ "$authn_azure_response" != "" ]]; then
      conjur_access_token=$(echo -n "$authn_azure_response" | base64 | tr -d '\r\n')
    else
      echo "Error authenticating to Conjur."
      conjur_access_token=""
    fi
}

################################
function getConjurSecret(){
    local secret_name=$1; shift
    # conjur_access_token accessed as global variable

    encoded_name=$(urlify $secret_name)
    # Retrieve a Conjur secret using the authn-azure Conjur access token
    secret=$(curl -sk -H "Authorization: Token token=\"${conjur_access_token}\"" \
      $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/${encoded_name})

    echo "Retrieved secret '${secret}' from Conjur!"
}

################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: encoded string
function urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        str=$(echo $str | sed 's=+=%2B=g')
        str=$(echo $str | sed 's=&=%26=g')
        str=$(echo $str | sed 's=@=%40=g')
        echo $str
}

main
