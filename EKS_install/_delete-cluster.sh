#!/bin/bash

source ./eks.config


EKS_CLUSTER_INFO=$(eksctl get cluster   \
        --name $EKS_CLUSTER_NAME        \
        --region $EKS_CLUSTER_REGION    \
        -o json | jq .[].Arn)

if [[ "$EKS_CLUSTER_INFO" != "" ]]; then
  echo
  read -p "Delete existing cluster $EKS_CLUSTER_NAME? " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    echo
    eksctl delete cluster                       \
        --name $EKS_CLUSTER_NAME                \
        --region $EKS_CLUSTER_REGION            \
        --wait
  else
    echo
    exit 0
  fi
else
  echo
  echo "Cluster $EKS_CLUSTER_NAME not found."
fi
