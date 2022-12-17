#!/bin/bash

if [[ -z "${CONJUR_HOME}" ]]; then
  echo "Set CONJUR_HOME to demo base directory."; exit -1
fi

source $CONJUR_HOME/config/conjur.config
source $CONJUR_HOME/bin/conjur_utils.sh

main() {
  if [[ "$PLATFORM" == "openshift" ]]; then
    $CLI login -u $CYBERARK_NAMESPACE_ADMIN
  fi
  ./stop
  if [[ "$1" == "clean" ]]; then
    exit 0
  fi
  mkdir -p ./manifests

  initialize_k8s_api_secrets
  verify_k8s_api_secrets 
  initialize_authn_jwt_secrets
  get_indented_certs
  create_configmaps
  deploy_follower
}

########################
initialize_k8s_api_secrets() {
  SA_TOKEN_NAME="$($CLI get secrets -n $CYBERARK_NAMESPACE_NAME \
    | grep "conjur-authn-service.*service-account-token" \
    | head -n1 \
    | awk '{print $1}')" && echo $SA_TOKEN_NAME

  # using SA_TOKEN_NAME from above step…
  echo "Adding DAP service account token as secret..."
  conjur_set_variable \
     conjur/authn-k8s/$CLUSTER_AUTHN_ID/kubernetes/service-account-token \
     $($CLI get secret -n $CYBERARK_NAMESPACE_NAME $SA_TOKEN_NAME -o json\
     | jq -r .data.token \
     | $BASE64D)

  # using SA_TOKEN_NAME from above step…
  echo
  echo
  echo "Adding ca cert as secret..."
  conjur_set_variable \
    conjur/authn-k8s/$CLUSTER_AUTHN_ID/kubernetes/ca-cert \
    "$($CLI get secret -n $CYBERARK_NAMESPACE_NAME $SA_TOKEN_NAME -o json \
      | jq -r '.data["ca.crt"]' \
      | $BASE64D)"

  echo
  echo
  echo "Adding k8s API URL as secret..."
  conjur_set_variable \
    conjur/authn-k8s/$CLUSTER_AUTHN_ID/kubernetes/api-url \
    "$($CLI config view --minify -o yaml | grep server | awk '{print $2}')"
}

########################
verify_k8s_api_secrets() {
  echo "Verifying K8s API values." 
  echo
  echo "Get k8s cert..."
  echo "$(conjur_get_variable conjur/authn-k8s/$CLUSTER_AUTHN_ID/kubernetes/ca-cert)" > k8s.crt
  echo
  echo "Get DAP service account token..."
  TOKEN=$(conjur_get_variable conjur/authn-k8s/$CLUSTER_AUTHN_ID/kubernetes/service-account-token)
  echo
  echo "Get K8s API URL..."
  API=$(conjur_get_variable conjur/authn-k8s/$CLUSTER_AUTHN_ID/kubernetes/api-url)
  echo
  echo -n "Verified if 'ok': "
  curl -s --cacert k8s.crt --header "Authorization: Bearer ${TOKEN}" $API/healthz && echo
  rm k8s.crt && unset API TOKEN SA_TOKEN_NAME
}

########################
initialize_authn_jwt_secrets() {
  echo "Initializing JWT authentication variables..."

  # hard-coded values, audience value may vary across K8s implementations
  conjur_set_variable						\
  	conjur/authn-jwt/$APP_NAMESPACE_NAME/token-app-property	\
	"sub"

  conjur_set_variable						\
  	conjur/authn-jwt/$APP_NAMESPACE_NAME/audience		\
	https://kubernetes.default.svc.cluster.local

  # convention here is to match identity path to authn-jwt service id,
  # which are currently required to be 1-1
  conjur_set_variable						\
  	conjur/authn-jwt/$APP_NAMESPACE_NAME/identity-path	\
	"/$APP_NAMESPACE_NAME"

  # values obtained from K8s cluster configuration
  jwks_uri=$($CLI get --raw /.well-known/openid-configuration | jq -r '.jwks_uri')
  public_keys=$($CLI get --raw $jwks_uri)
  issuer=$($CLI get --raw /.well-known/openid-configuration | jq -r '.issuer')

  conjur_set_variable                                           \
        conjur/authn-jwt/$APP_NAMESPACE_NAME/public-keys        \
        "{\"type\":\"jwks\", \"value\":$public_keys}"

  conjur_set_variable						\
  	conjur/authn-jwt/$APP_NAMESPACE_NAME/issuer		\
	$issuer
}

########################
get_indented_certs() {
  cat $LEADER_CERT_FILE \
  | awk '{ print "    " $0 }' > master-cert.indented
  cat $FOLLOWER_CERT_FILE \
  | awk '{ print "    " $0 }' > follower-cert.indented
}

########################
create_configmaps() {
  # replace non-file values in configmap manifest
  cat ./templates/conjur-config-map-manifest.template.yaml 			\
    | sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" 			\
    | sed -e "s#{{ CONJUR_LEADER_HOSTNAME }}#$CONJUR_LEADER_HOSTNAME#g" 	\
    | sed -e "s#{{ CONJUR_LEADER_PORT }}#$CONJUR_LEADER_PORT#g"		 	\
    | sed -e "s#{{ CYBERARK_NAMESPACE_NAME }}#$CYBERARK_NAMESPACE_NAME#g"	\
    | sed -e "s#{{ CLUSTER_AUTHN_ID }}#$CLUSTER_AUTHN_ID#g" 			\
    > ./temp1

  # Add Master cert to configmap manifest
  # (see: https://stackoverflow.com/questions/6790631/use-the-contents-of-a-file-to-replace-a-string-using-sed)
  sed -e '/{{ CONJUR_LEADER_CERTIFICATE }}/{
		s/{{ CONJUR_LEADER_CERTIFICATE }}//g
		r ./master-cert.indented
	}' ./temp1 					\
    > ./temp2

  # Add Follower cert to configmap manifest
  sed -e '/{{ CONJUR_FOLLOWER_CERTIFICATE }}/{
		s/{{ CONJUR_FOLLOWER_CERTIFICATE }}//g
		r ./follower-cert.indented
	}' ./temp2 					\
    > ./manifests/conjur-cm-manifest.yaml
  rm ./temp? ./*.indented
  $CLI apply -f ./manifests/conjur-cm-manifest.yaml -n $CYBERARK_NAMESPACE_NAME

  cat ./templates/follower-config-map-manifest.template.yaml 		\
    | sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#g" 		\
    | sed -e "s#{{ CONJUR_LEADER_HOSTNAME }}#$CONJUR_LEADER_HOSTNAME#g" \
    | sed -e "s#{{ CONJUR_LEADER_PORT }}#$CONJUR_LEADER_PORT#g"	 	\
    | sed -e "s#{{ CLUSTER_AUTHN_ID }}#$CLUSTER_AUTHN_ID#g" 		\
    | sed -e "s#{{ CONJUR_AUTHENTICATORS }}#$CONJUR_AUTHENTICATORS#g" 	\
    > ./manifests/follower-cm-manifest.yaml
  $CLI apply -f ./manifests/follower-cm-manifest.yaml -n $CYBERARK_NAMESPACE_NAME
}

########################
deploy_follower() {
  cat ./templates/follower-deployment-manifest.template.yaml 		\
    | sed -e "s#{{ CONJUR_LEADER_HOSTNAME }}#$CONJUR_LEADER_HOSTNAME#g" \
    | sed -e "s#{{ CONJUR_LEADER_HOST_IP }}#$CONJUR_LEADER_HOST_IP#g"		\
    | sed -e "s#{{ CONJUR_SEEDFETCHER_IMAGE }}#$SEEDFETCHER_IMAGE#g" 	\
    | sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$APPLIANCE_IMAGE#g" 	\
  > ./manifests/follower-deployment-manifest.yaml
  $CLI apply -f ./manifests/follower-deployment-manifest.yaml -n $CYBERARK_NAMESPACE_NAME

  sleep 3
  follower_pod_name=$($CLI get pods -n $CYBERARK_NAMESPACE_NAME | grep conjur-follower | grep -v Terminating | tail -1 | awk '{print $1}')
}

main "$@"
