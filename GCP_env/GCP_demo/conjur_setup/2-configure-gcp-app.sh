#!/bin/bash
set -ou pipefail

source ./gcp.config

export PROJECT_NAME=gcp-demo
export CONJUR_HOST_ID=gcp-client
export FQ_CONJUR_HOST_ID=$PROJECT_NAME/$CONJUR_HOST_ID

main() {
  collect_info_from_gcp_token
#  load_application_policy
  authenticate_conjur_host
}

################################
collect_info_from_gcp_token() {
  GCP_TOKEN=$(curl -s -G -H "Metadata-Flavor: Google" \
    --data-urlencode "audience=conjur/$CONJUR_ACCOUNT/host/$FQ_CONJUR_HOST_ID" \
    --data-urlencode "format=full" \
    "http://metadata/computeMetadata/v1/instance/service-accounts/default/identity")
  GCP_TOKEN_PAYLOAD=$(echo $GCP_TOKEN | cut -d "." -f 2 | base64 -d 2> /dev/null)

  export INSTANCE_NAME=$(echo $GCP_TOKEN_PAYLOAD | jq -r .google.compute_engine.instance_name)
  export PROJECT_ID=$(echo $GCP_TOKEN_PAYLOAD | jq -r .google.compute_engine.project_id)
  export SERVICE_ACCOUNT_ID=$(echo $GCP_TOKEN_PAYLOAD | jq -r .sub)
  export SERVICE_ACCOUNT_EMAIL=$(echo $GCP_TOKEN_PAYLOAD | jq -r .email)
}

################################
load_application_policy() {
  cat policy/templates/gcp-app.template.yml				\
  | sed -e "s#{{ PROJECT_NAME }}#$PROJECT_NAME#g"                	\
  | sed -e "s#{{ CONJUR_HOST_ID }}#$CONJUR_HOST_ID#g"                	\
  | sed -e "s#{{ INSTANCE_NAME }}#$INSTANCE_NAME#g"                	\
  | sed -e "s#{{ PROJECT_ID }}#$PROJECT_ID#g"                		\
  | sed -e "s#{{ SERVICE_ACCOUNT_ID }}#$SERVICE_ACCOUNT_ID#g"		\
  | sed -e "s#{{ SERVICE_ACCOUNT_EMAIL }}#$SERVICE_ACCOUNT_EMAIL#g"     \
  > policy/$PROJECT_NAME-$CONJUR_HOST_ID.yml

  cat policy/$PROJECT_NAME-$CONJUR_HOST_ID.yml		\
  | $DOCKER exec -i conjur-cli conjur policy load root -
}

################################
authenticate_conjur_host() {
  CONJUR_TOKEN=$(curl -sk https://$CONJUR_LEADER_HOSTNAME/authn-gcp/$CONJUR_ACCOUNT/authenticate \
  -H Accept-Encoding: base64				\
  -H Content-Type: application/x-www-form-urlencoded	\
  --data-urlencode "jwt=$GCP_TOKEN")
  echo $CONJUR_TOKEN
}

main "$@"
