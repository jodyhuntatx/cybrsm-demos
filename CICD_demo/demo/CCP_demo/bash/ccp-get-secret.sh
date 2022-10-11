#!/bin/bash

export CCP_HOST=192.168.50.131
export APP_ID=ANSIBLE
export SAFE=CICD_Secrets
export OBJECT=MySQL

curl -sk "https://$CCP_HOST/AIMWebService/api/Accounts?AppID=$APP_ID&Query=Safe=$SAFE;Object=$OBJECT" | jq .
