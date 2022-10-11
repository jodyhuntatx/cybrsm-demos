#!/bin/bash

export BASEURL="https://comp_server"
export APPID="ANSIBLE"
export SAFE="CICD_Secrets"
export FOLDER="Root"
export OBJECTNAME="MySQL"
#set -x
RESPONSE=$(curl -k -s \
  "$BASEURL/AIMWebService/api/Accounts?AppID=$APPID&Safe=$SAFE&Folder=$FOLDER&Object=$OBJECTNAME")
PASSWORD=$(echo $RESPONSE | jq -r .Content)
echo "The password is: ${PASSWORD}"
