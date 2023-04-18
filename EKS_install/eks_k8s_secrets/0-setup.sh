#!/bin/bash
set -euo pipefail
source ./conjur-cloud-vars.sh

if [[ "$(which jq)" == "" ]]; then
  echo "This script uses jq for JSON parsing. Please install it..."
  exit -1
fi

echo "Setting up authn-jwt for EKS cluster..."

# create policy branch for workload identities
./ccloud-cli.sh append data policy/workloads-branch.yml

# load policy for authn-jwt for cluster
./ccloud-cli.sh append conjur/authn-jwt	policy/authn-jwt-k8s-eks.yml

# set values for authn-jwt variables
ISSUER=$(kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer')
./ccloud-cli.sh set conjur/authn-jwt/k8s-eks/issuer "$ISSUER"

PUBLIC_KEYS=$(curl -s $ISSUER/keys)
if [[ "$PUBLIC_KEYS" == "" ]]; then
  echo "Error getting public keys from issuer $ISSUER in EKS cluster."
  exit -1
fi
./ccloud-cli.sh set conjur/authn-jwt/k8s-eks/public-keys "{\"type\":\"jwks\", \"value\": $PUBLIC_KEYS}"
./ccloud-cli.sh set conjur/authn-jwt/k8s-eks/identity-path "data/workloads"
./ccloud-cli.sh set conjur/authn-jwt/k8s-eks/token-app-property "sub"
./ccloud-cli.sh set conjur/authn-jwt/k8s-eks/audience "conjur"
./ccloud-cli.sh enable authn-jwt k8s-eks
./ccloud-cli.sh status authn-jwt k8s-eks
