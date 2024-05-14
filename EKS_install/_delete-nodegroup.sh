#!/bin/bash

source ./eks.config

EKS_NODEGROUP_NAMES=$(eksctl get nodegroup	\
	--cluster JodyEKScluster		\
	--region us-west-2			\
	-o json | jq -r .[].Name)

if [[ "$EKS_NODEGROUP_NAMES" != "" ]]; then
  for i in $EKS_NODEGROUP_NAMES; do
    echo
    read -p "Delete nodegroup $i? " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      echo
      eksctl delete nodegroup \
        --cluster $EKS_CLUSTER_NAME	\
        --region $EKS_CLUSTER_REGION	\
	--name $i			\
        --wait
    else
      echo
      exit 0
    fi
  done
else
  echo "Cluster $EKS_CLUSTER_NAME has no nodegroups."
fi
