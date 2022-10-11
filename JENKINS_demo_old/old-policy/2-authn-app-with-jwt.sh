#!/bin/bash
set -eou pipefail

source ../config/conjur.config
source ../bin/conjur_utils.sh

export JWT_SERVICE_ID=invesco
export JWT_CLAIM_NAME=appid
export PROJECT_NAME=invescotest
export APP_IDENTITY=jwtclient
export REST_ENDPOINT=https://$CONJUR_LEADER_HOSTNAME/authn-jwt/$JWT_SERVICE_ID/$CONJUR_ACCOUNT/host%2F$PROJECT_NAME%2F$APP_IDENTITY/authenticate
export JWT=$(cat expired-azure-ad.jwt)

echo $(curl -sk "$REST_ENDPOINT"			\
  -H 'Content-Type: application/x-www-form-urlencoded'	\
  -H "Accept-Encoding: base64" 				\
  --data-urlencode "jwt=$JWT")

