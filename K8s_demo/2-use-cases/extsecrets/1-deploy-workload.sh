#!/bin/bash
set -uo pipefail

source ./conjur-cloud-vars.sh
kubectl create ns $NAMESPACE
kubectl apply -f ConjurSecretStore.yaml -n $NAMESPACE
helm install $NAMESPACE ./charts/app -n $NAMESPACE --set namespace=$NAMESPACE --debug
