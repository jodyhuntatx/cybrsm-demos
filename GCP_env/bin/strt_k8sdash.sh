#!/bin/bash
                # set CONJUR_HOME to parent directory of this script
CONJUR_HOME="$(ls $0 | rev | cut -d "/" -f2- | rev)/.."
source $CONJUR_HOME/config/conjur.config

TOKEN=$(kubectl -n kube-system describe secret default| awk '$1=="token:"{print $2}')
kubectl config set-credentials kubernetes-admin --token="${TOKEN}"
kubectl apply -f $CONJUR_HOME/bin/k8sdashboard.yaml
kubectl proxy &> /dev/null &
echo "Admin token: $TOKEN"
