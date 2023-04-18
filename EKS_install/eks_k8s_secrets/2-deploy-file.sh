#!/bin/bash
set -uo pipefail

source ./conjur-cloud-vars.sh

# Getting server certificate for Conjur Cloud
openssl s_client -connect "$CONJUR_CLOUD_FQDN":443 </dev/null 2>/dev/null \
  | openssl x509 -inform pem -text > conjur_cloud.pem

echo "Deploying workload with Helm."
echo "Secrets Provider running as Sidecar."
echo "Pushing secrets to File."

# Helm install Release names does not allow '_' use '-'
helm install conjur-cloud-k8s-eks-secrets 			\
     ./charts/ccloud-file					\
     --namespace default 					\
     --set namespace=$NAMESPACE					\
     --set account="$CONJUR_ACCOUNT" 				\
     --set conjur_fqdn="$CONJUR_CLOUD_FQDN" 			\
     --set conjur_cert="$(cat conjur_cloud.pem | base64)" 	\
     --debug

rm conjur_cloud.pem
