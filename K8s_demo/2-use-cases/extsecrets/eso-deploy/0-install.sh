#!/bin/bash
kubectl create ns external-secrets
helm install external-secrets ./deploy/charts/external-secrets -n external-secrets
echo
echo "Wait until all deployments are ready before creating secrets."
echo "    kubectl get deployment -n external-secrets"
kubectl get deployment -n external-secrets
