#!/bin/bash

source ./eks.config

EKS_NODEGROUP_NAMES=$(eksctl get nodegroup	\
	--cluster JodyEKScluster		\
	--region us-west-2			\
	-o json | jq -r .[].Name)

if [[ "$EKS_NODEGROUP_NAMES" != "" ]]; then
  echo "Cluster already has a nodegroup. Use scaling to add or remove nodes."
  exit -1
fi

#	--version auto			\

eksctl create nodegroup			\
	--cluster $EKS_CLUSTER_NAME	\
	--region $EKS_CLUSTER_REGION	\
	--name $EKS_CLUSTER_NAME-ng-$(openssl rand -hex 2)	\
	--node-type $EKS_NODE_TYPE	\
	--nodes $EKS_NODEGROUP_SIZE	\
	--nodes-max $EKS_NODEGROUP_SIZE	\
	--node-volume-size 20		\
	--ssh-public-key $EKS_SSH_PUB_KEY	\
	--instance-prefix $EKS_CLUSTER_NAME	\
	--managed
