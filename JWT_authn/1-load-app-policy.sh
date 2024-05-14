#!/bin/bash
set -eou pipefail

source ../config/conjur.config
source ../bin/conjur_utils.sh

export JWT_APP_POLICY_TEMPLATE=app-authn-jwt.yml.template
export SERVICE_ID=jenkins

export PROJECT_NAME=jenkins
export APP_IDENTITY=PluginDemo-Pipeline

# Note: Claim names below must support enforced claims for authn-jwt endpoint
export JWT_CLAIM1_NAME=jenkins_name
export JWT_CLAIM1_VALUE=PluginDemo-Pipeline
export JWT_CLAIM2_NAME=jenkins_task_noun
export JWT_CLAIM2_VALUE=Build
export JWT_CLAIM3_NAME=jenkins_pronoun
export JWT_CLAIM3_VALUE=Pipeline

cat ./templates/$JWT_APP_POLICY_TEMPLATE			\
  | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#g"			\
  | sed -e "s#{{ PROJECT_NAME }}#$PROJECT_NAME#g"		\
  | sed -e "s#{{ APP_IDENTITY }}#$APP_IDENTITY#g"		\
  | sed -e "s#{{ JWT_CLAIM1_NAME }}#$JWT_CLAIM1_NAME#g"		\
  | sed -e "s#{{ JWT_CLAIM1_VALUE }}#$JWT_CLAIM1_VALUE#g"	\
  | sed -e "s#{{ JWT_CLAIM2_NAME }}#$JWT_CLAIM2_NAME#g"		\
  | sed -e "s#{{ JWT_CLAIM2_VALUE }}#$JWT_CLAIM2_VALUE#g"	\
  | sed -e "s#{{ JWT_CLAIM3_NAME }}#$JWT_CLAIM3_NAME#g"		\
  | sed -e "s#{{ JWT_CLAIM3_VALUE }}#$JWT_CLAIM3_VALUE#g"	\
  > ./policy/$JWT_APP_POLICY_TEMPLATE

conjur_append_policy root ./policy/$JWT_APP_POLICY_TEMPLATE delete
