#!/bin/bash
source ./conjur-cloud-vars.sh
helm delete $NAMESPACE
kubectl delete ns $NAMESPACE
