#!/bin/bash

source ./eks.config

if [[ $# != 1 ]]; then
  echo "Usage: $0 <new-nodegroup-size>"
  exit -1
fi

NODEGROUP_SIZE=$1

EKS_NODEGROUP_NAMES=$(eksctl get nodegroup	\
	--cluster JodyEKScluster		\
	--region us-west-2			\
	-o json | jq -r .[].Name)

if [[ "$EKS_NODEGROUP_NAMES" != "" ]]; then
  for nodename in $EKS_NODEGROUP_NAMES; do
    echo
    read -p "Scale nodegroup $nodename to $NODEGROUP_SIZE nodes? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      eksctl scale nodegroup \
        --cluster $EKS_CLUSTER_NAME	\
        --region $EKS_CLUSTER_REGION	\
	--name $nodename		\
        --nodes $NODEGROUP_SIZE		\
        --nodes-min 0			\
        --nodes-max $NODEGROUP_SIZE
    fi
  done
else
  echo "Cluster $EKS_CLUSTER_NAME has no nodegroups."
fi
