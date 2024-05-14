#!/bin/bash
set -eou pipefail

source ../../config/conjur.config
source ../../bin/conjur_utils.sh
source ../jenkins-demo.config

cat ./templates/$JWT_APP_POLICY_TEMPLATE			\
  | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"			\
  | sed -e "s#{{ PROJECT_NAME }}#$PROJECT_NAME#g"		\
  | sed -e "s#{{ APP_IDENTITY }}#$APP_IDENTITY#g"		\
  | sed -e "s#{{ JWT_CLAIM1_NAME }}#$JWT_CLAIM1_NAME#g"		\
  | sed -e "s#{{ JWT_CLAIM1_VALUE }}#$JWT_CLAIM1_VALUE#g"	\
  > ./policy/$APP_IDENTITY.yml

#  | sed -e "s#{{ JWT_CLAIM2_NAME }}#$JWT_CLAIM2_NAME#g"		\
#  | sed -e "s#{{ JWT_CLAIM2_VALUE }}#$JWT_CLAIM2_VALUE#g"	\
#  | sed -e "s#{{ JWT_CLAIM3_NAME }}#$JWT_CLAIM3_NAME#g"		\
#  | sed -e "s#{{ JWT_CLAIM3_VALUE }}#$JWT_CLAIM3_VALUE#g"	\

conjur_update_policy root ./policy/$APP_IDENTITY.yml
